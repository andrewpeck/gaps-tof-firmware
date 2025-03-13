-- Copyright 2023-2025 Andrew Peck

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.

-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.

-- 3. Neither the name of the copyright holder nor the names of its contributors
-- may be used to endorse or promote products derived from this software without
-- specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity tiu_uart is
  generic(
    FREQ       : integer := 100_000_000;
    TIMESTAMPB : integer := 32;
    GPSB       : integer := 48
    );
  port(
    clock      : in std_logic;
    reset      : in std_logic;
    tiu_uart_i : in std_logic;

    timestamp_i : in std_logic_vector (TIMESTAMPB-1 downto 0);

    tiu_gps_word_valid_o : out std_logic;
    tiu_gps_word_o       : out std_logic_vector (GPSB-1 downto 0) := (others => '0');

    timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0) := (others => '0');
    timestamp_valid_o : out std_logic
    );
end;

architecture rtl of tiu_uart is

  constant TIU_HOLDOFF_CNT_MAX : natural := 2**20-1;

  signal tiu_uart_byte     : std_logic_vector (7 downto 0);
  signal tiu_uart_byte_dav : std_logic;
  signal tiu_falling_cnt   : natural                              := TIU_HOLDOFF_CNT_MAX;
  signal tiu_uart_i_sr     : std_logic_vector (2 downto 0)        := (others => '0');
  signal tiu_falling       : std_logic                            := '0';
  signal tiu_gps_buf       : std_logic_vector (GPSB-8-1 downto 0) := (others => '0');
  signal tiu_byte_cnt      : integer range 0 to tiu_gps_word_o'length/8;

begin

  --------------------------------------------------------------------------------
  -- Timestamp In
  --------------------------------------------------------------------------------

  gps_uart_inst : entity work.tiny_uart
    generic map (
      WLS    => 8,                      -- word length select; number of data bits     [ integer ]
      CLK    => FREQ,                   -- master clock frequency in Hz                [ integer ]
      BPS    => 9600,                   -- transceive baud rate in Bps                 [ integer ]
      SBS    => 1,                      -- Stop bit select, only one/two stopbit       [ integer ]
      PI     => true,                   -- Parity inhibit, true: inhibit               [ boolean ]
      EPE    => true,                   -- Even parity enable, true: even, false: odd  [ boolean ]
      DEBU   => 4,                      -- Number of debouncer stages                  [ integer ]
      TXIMPL => true,                   -- implement UART TX path                      [ boolean ]
      RXIMPL => true)                   -- implement UART RX path                      [ boolean ]
    port map (
      R   => reset,
      C   => clock,
      TXD => open,
      RXD => tiu_uart_i,

      RR => tiu_uart_byte,              --! Receiver Holding Register Data Output
      PE => open,                       --! Parity error
      FE => open,                       --! Framing error
      DR => tiu_uart_byte_dav,          --! Data Received, one clock cycle high
      TR => (others => '0'),            --! Transmitter Holding Register Data Input

      THRE => open,                     --! Transmitter Holding Register Empty
      THRL => '0',                      --! Transmitter Holding Register Load, one clock cycle high
      TRE  => open                      --! Transmitter Register Empty
      );

  --------------------------------------------------------------------------------
  -- Timestamp Latch
  -- TODO: add a timeout, make sure it does not get stuck in some weird state
  -- TODO: convert to an explicit SM
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_gps_word_valid_o <= '0';

      -- synchronize the byte counter to the falling edge of the pulse
      if (tiu_falling = '1') then

        tiu_byte_cnt <= 0;

      elsif (tiu_uart_byte_dav = '1') then

        if (tiu_byte_cnt < 5) then
          tiu_byte_cnt <= tiu_byte_cnt + 1;
          tiu_gps_buf(8*(tiu_byte_cnt+1)-1 downto 8*tiu_byte_cnt)
            <= tiu_uart_byte;
        else
          tiu_byte_cnt         <= 0;
          tiu_gps_word_o       <= tiu_uart_byte & tiu_gps_buf;
          tiu_gps_word_valid_o <= '1';
        end if;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Timestamp
  -- on the falling edge of the tiu_uart_i signal, latch the local MTB timestamp
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      tiu_uart_i_sr(0) <= tiu_uart_i;

      for I in 1 to tiu_uart_i_sr'length-1 loop
        tiu_uart_i_sr(I) <= tiu_uart_i_sr(I-1);
      end loop;

      tiu_falling <= '0';

      if (tiu_falling_cnt = 0 and tiu_uart_i_sr(2) = '1' and tiu_uart_i_sr(1) = '0') then
        tiu_falling     <= '1';
        tiu_falling_cnt <= TIU_HOLDOFF_CNT_MAX;
      elsif (tiu_falling_cnt > 0) then
        tiu_falling_cnt <= tiu_falling_cnt - 1;
      end if;

      timestamp_valid_o <= '0';

      if (tiu_falling = '1') then
        timestamp_o       <= timestamp_i;
        timestamp_valid_o <= '1';
      end if;

    end if;
  end process;

end rtl;
