library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity spi_rx is
  port(
    clock   : in  std_logic;
    sclk    : in  std_logic;
    sdat    : in  std_logic;
    valid_o : out std_logic;
    data_o  : out std_logic_vector (31 downto 0)
    );
end spi_rx;

architecture behavioral of spi_rx is

  signal data            : std_logic_vector (31 downto 0);
  signal sclk_r, sclk_rr : std_logic := '0';
  signal sdat_r, sdat_rr : std_logic := '0';

  signal bit_cnt : integer range 0 to 31 := 31;

  constant timeout_cnt_max : integer                            := 4000;
  signal timeout_cnt       : integer range 0 to timeout_cnt_max := 0;

  signal done : boolean := false;

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then


      -- input ffs
      sclk_r <= sclk;
      sdat_r <= sdat;

      sclk_rr <= sclk_r;
      sdat_rr <= sdat_r;

      -- timeout watchdog
      -- reset in case the whole SPI packet doesn't show up
      if (bit_cnt /= 31) then
        if (timeout_cnt /= timeout_cnt_max) then
          timeout_cnt <= timeout_cnt + 1;
        end if;
      else
        timeout_cnt <= 0;
      end if;

      valid_o <= '0';

      if (timeout_cnt = timeout_cnt_max) then
        bit_cnt     <= 31;
        timeout_cnt <= 0;
        data_o      <= x"FFFFFFFF";
        valid_o     <= '1';

      elsif (sclk_rr = '0' and sclk_r = '1') then  -- RISING edge of SCLK

        data(bit_cnt) <= sdat_rr;

        if (bit_cnt = 0) then
          bit_cnt <= 31;
          data_o  <= data(31 downto 1) & sdat_rr;
          valid_o <= '1';
        else
          bit_cnt <= bit_cnt - 1;
        end if;

      end if;

    end if;
  end process;
end behavioral;
