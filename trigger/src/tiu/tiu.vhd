-- Copyright 2023-2025 Andrew Peck, University of California

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
use ieee.math_real.all;

entity tiu is
  generic (
    TIMESTAMPB : integer := 32;
    GPSB       : integer := 48;
    FREQ       : integer := 100_000_000;
    EVENTCNTB  : integer := 32;
    DEBUG      : boolean := false
    );
  port(

    clock : in std_logic;
    reset : in std_logic;

    -- tiu physical signals
    tiu_busy_i    : in  std_logic;
    tiu_serial_o  : out std_logic;
    tiu_uart_i    : in  std_logic;
    tiu_trigger_o : out std_logic;

    -- config
    send_event_cnt_on_timeout : in std_logic := '1';
    tiu_busy_ignore_i         : in std_logic;

    -- mt trigger signals
    pre_trigger_i : in std_logic;
    event_cnt_i   : in std_logic_vector (EVENTCNTB-1 downto 0);
    timestamp_i   : in std_logic_vector (TIMESTAMPB-1 downto 0);

    -- outputs

    tiu_busy_length_o : out std_logic_vector (31 downto 0);

    tiu_stuck_o : out std_logic := '0';

    global_busy_o : out std_logic;

    tiu_gps_word_valid_o : out std_logic;
    tiu_gps_word_o       : out std_logic_vector (GPSB-1 downto 0) := (others => '0');

    timestamp_o       : out std_logic_vector (TIMESTAMPB-1 downto 0) := (others => '0');
    timestamp_valid_o : out std_logic;

    tiu_timeout_o : out std_logic

    );
end tiu;

architecture behavioral of tiu is

  constant CLK_PERIOD_US       : real    := 1000000.0/real(FREQ);
  constant tiu_timeout_cnt_max : integer := integer(1.05 / CLK_PERIOD_US);  -- 105 cycles

  signal tiu_busy_i_falling : std_logic;
  signal tiu_busy           : std_logic := '0';

  signal tiu_ack    : std_logic                    := '0';
  signal tiu_ack_sr : std_logic_vector(3 downto 0) := (others => '0');

  type tx_init_state_t is (READY_FOR_TRIGGER, WAIT_FOR_ACK, INIT_TX, WAIT_FOR_TX_DONE, WAIT_FOR_NOT_BUSY);
  signal tx_init_state : tx_init_state_t := READY_FOR_TRIGGER;

  --------------------------------------------------------------------------------
  -- Trigger Logic
  --------------------------------------------------------------------------------

  signal trigger          : std_logic;
  signal pretrigger_latch : std_logic                              := '0';
  signal ready_to_trigger : std_logic                              := '0';
  signal event_cnt        : std_logic_vector (event_cnt_i'range)   := (others => '0');
  signal tiu_timeout_cnt  : integer range 0 to tiu_timeout_cnt_max := 0;
  signal tiu_tx_busy      : std_logic;
  signal tiu_tx_done      : std_logic;
  signal tiu_init_tx      : std_logic                              := '0';

  --------------------------------------------------------------------------------
  -- Watchdog
  --------------------------------------------------------------------------------

  constant tiu_stuck_cnt_max : integer := 1_000_000_000;
  signal tiu_stuck_cnt       : unsigned (31 downto 0);
  signal tiu_busy_cnt        : unsigned (31 downto 0);

begin

  tiu_busy <= (tiu_busy_i and not tiu_busy_ignore_i);
  trigger  <= pre_trigger_i and not tiu_busy;

  --------------------------------------------------------------------------------
  -- ACK Glitch Filter
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      -- if we ignore the busy we are always acknowledged
      tiu_ack_sr(0) <= tiu_busy or tiu_busy_ignore_i;
      for I in 1 to tiu_ack_sr'length-1 loop
        tiu_ack_sr(I) <= tiu_ack_sr(I-1);
      end loop;
      tiu_ack <= and_reduce(tiu_ack_sr);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Out
  --------------------------------------------------------------------------------
  -- or the statemachine derived ready_to_trigger signal with the async
  -- source of the trigger so that it is activated 1 clock cycle ahead of the
  -- state machine. this reduces latency by 1 clock. thanks to the OR, once the
  -- state machine takes effect the active hi trigger signal will get taken
  -- over and held high until the ack comes back from the tiu
  --
  -- NOTE: maybe should gate this by the state of the state machine?
  -- there might be a condition where a trigger comes in before BUSY is asserted?
  tiu_trigger_o    <= (ready_to_trigger and pre_trigger_i) or pretrigger_latch;
  ready_to_trigger <= '1' when (tx_init_state = READY_FOR_TRIGGER) else '0';
  global_busy_o    <= (not ready_to_trigger) or tiu_busy;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      -- upon receiving a trigger, we should:
      --  1) assert the trigger output
      --  2) wait a for 1.05 us for the ACK signal (busy) to come from the SiLI
      --     - If ACK does not come, timeout and do ???
      --  3) When ACK is received, send the event counter
      --  4) When ACK is deasserted, ready for the next trigger

      tiu_init_tx <= '0';
      tiu_timeout_o <= '0';

      case tx_init_state is

        when READY_FOR_TRIGGER =>

          pretrigger_latch <= '0';

          -- start a trigger
          if (trigger = '1') then
            pretrigger_latch <= '1';
            tiu_timeout_cnt  <= tiu_timeout_cnt_max;
            tx_init_state    <= WAIT_FOR_ACK;
          end if;

        -- when the busy/ack is received, deassert the trigger output and start the
        -- event count serializer
        when WAIT_FOR_ACK =>

          event_cnt <= event_cnt_i;

          -- acknowledgment received
          if tiu_ack = '1' then
            tx_init_state <= INIT_TX;

          -- still waiting for the ack
          elsif (tiu_timeout_cnt > 0) then
            tiu_timeout_cnt <= tiu_timeout_cnt - 1;

          -- timeout
          elsif (tiu_timeout_cnt = 0) then

            tiu_timeout_o <= '1';

            if (send_event_cnt_on_timeout = '1') then
              tx_init_state <= INIT_TX;
            else
              tx_init_state <= READY_FOR_TRIGGER;
            end if;

          end if;

        when INIT_TX =>

          pretrigger_latch <= '0';
          tx_init_state    <= WAIT_FOR_TX_DONE;
          tiu_init_tx      <= '1';

        when WAIT_FOR_TX_DONE =>

          if (tiu_tx_done = '1') then
            tx_init_state <= WAIT_FOR_NOT_BUSY;
          end if;

        when WAIT_FOR_NOT_BUSY =>

          if (tiu_busy = '0') then
            tx_init_state <= READY_FOR_TRIGGER;
          end if;

        when others =>
          tx_init_state <= READY_FOR_TRIGGER;

      end case;

      if (reset = '1') then
        tx_init_state <= READY_FOR_TRIGGER;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Count Out
  --------------------------------------------------------------------------------

  tiu_tx_inst : entity work.tiu_tx
    generic map (
      EVENTCNTB => EVENTCNTB,
      DIV       => 100
      )
    port map (
      clock       => clock,
      reset       => reset,
      serial_o    => tiu_serial_o,
      trg_i       => tiu_init_tx,
      event_cnt_i => event_cnt,
      busy_o      => tiu_tx_busy,
      done_o      => tiu_tx_done
      );

  --------------------------------------------------------------------------------
  -- GPS/Timestamp Handling
  --------------------------------------------------------------------------------

  tiu_uart_inst : entity work.tiu_uart
    generic map (
      FREQ       => FREQ,
      TIMESTAMPB => TIMESTAMPB,
      GPSB       => GPSB
      )
    port map (
      clock                => clock,
      reset                => reset,
      timestamp_i          => timestamp_i,
      tiu_uart_i           => tiu_uart_i,
      tiu_gps_word_valid_o => tiu_gps_word_valid_o,
      tiu_gps_word_o       => tiu_gps_word_o,
      timestamp_o          => timestamp_o,
      timestamp_valid_o    => timestamp_valid_o
      );

  --------------------------------------------------------------------------------
  -- Monitor
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if tiu_busy_i = '0' then
        tiu_stuck_cnt <= (others => '0');
      elsif (tiu_stuck_cnt < tiu_stuck_cnt_max) then
        tiu_stuck_cnt <= tiu_stuck_cnt + 1;
      end if;

      if (tiu_stuck_cnt = tiu_stuck_cnt_max) then
        tiu_stuck_o <= '1';
      else
        tiu_stuck_o <= '0';
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Busy Length Monitor
  --------------------------------------------------------------------------------

  oneshot_fe : entity work.oneshot
    port map (clk => clock, d => not tiu_busy_i, q => tiu_busy_i_falling);

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if tiu_busy_i_falling = '1' then
        tiu_busy_length_o <= std_logic_vector(tiu_busy_cnt);
      end if;

      if tiu_busy_i = '1' then
        tiu_busy_cnt <= tiu_busy_cnt + 1;
      elsif tiu_busy_i = '0' then
        tiu_busy_cnt <= (others => '0');
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- ILA
  --------------------------------------------------------------------------------

  ila_gen : if (DEBUG) generate

    component ila_mt is
      port (
        clk     : in std_logic;
        probe0  : in std_logic_vector(0 downto 0);
        probe1  : in std_logic_vector(0 downto 0);
        probe2  : in std_logic_vector(74 downto 0);
        probe3  : in std_logic_vector(7 downto 0);
        probe4  : in std_logic_vector(7 downto 0);
        probe5  : in std_logic_vector(0 downto 0);
        probe6  : in std_logic_vector(0 downto 0);
        probe7  : in std_logic_vector(0 downto 0);
        probe8  : in std_logic_vector(0 downto 0);
        probe9  : in std_logic_vector(1 downto 0);
        probe10 : in std_logic_vector(31 downto 0);
        probe11 : in std_logic_vector(31 downto 0);
        probe12 : in std_logic_vector(31 downto 0);
        probe13 : in std_logic_vector(31 downto 0);
        probe14 : in std_logic_vector(31 downto 0)
        );
    end component ila_mt;

  begin

    ila_mt_inst : ila_mt
      port map (
        clk                   => clock,
        probe0(0)             => tiu_busy,
        probe1(0)             => '0',
        probe2(0)             => tiu_busy_i,
        probe2(1)             => tiu_serial_o,
        probe2(2)             => '0',
        probe2(3)             => ready_to_trigger,
        probe2(4)             => pre_trigger_i,
        probe2(5)             => global_busy_o,
        probe2(6)             => timestamp_valid_o,
        probe2(7)             => tiu_gps_word_valid_o,
        probe2(55 downto 8)   => tiu_gps_word_o,
        probe2(57 downto 56)  => (others => '0'),
        probe2(60 downto 58)  => std_logic_vector(to_unsigned(tx_init_state_t'pos(tx_init_state), 3)),
        probe2(61)            => pretrigger_latch,
        probe2(62)            => ready_to_trigger,
        probe2(63)            => tiu_tx_done,
        probe2(64)            => '0',
        probe2(65)            => '0',
        probe2(74 downto 66)  => (others => '0'),
        probe3(3 downto 0)    => (others => '0'),
        probe3(4)             => '0',
        probe3(5)             => tiu_ack,
        probe3(6)             => '0',
        probe3(7)             => '0',
        probe4(4 downto 0)    => (others => '0'),
        probe4(5)             => '0',
        probe4(6)             => '0',
        probe4(7)             => '0',
        probe5(0)             => '0',
        probe6(0)             => '0',
        probe7(0)             => '0',
        probe8(0)             => '0',
        probe9(1 downto 0)    => (others => '0'),
        probe10(31 downto 0)  => event_cnt,
        probe11(31 downto 0)  => timestamp_o,
        probe12(31 downto 0)  => timestamp_i,
        probe13(0)            => '0',
        probe13(1)            => tiu_init_tx,
        probe13(2)            => tiu_timeout_o,
        probe13(3)            => tiu_busy_ignore_i,
        probe13(4)            => tiu_tx_busy,
        probe13(5)            => tiu_uart_i,
        probe13(6)            => tiu_trigger_o,
        probe13(7)            => '0',
        probe13(15 downto 8)  => (others => '0'),
        probe13(19 downto 16) => (others => '0'),
        probe13(20)           => '0',
        probe13(28 downto 21) => (others => '0'),
        probe13(29)           => '0',
        probe13(30)           => '0',
        probe13(31)           => '0',
        probe14(31 downto 0)  => (others => '0')
        );
  end generate;

end behavioral;
