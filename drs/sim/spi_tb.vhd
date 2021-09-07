library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_tb is
end spi_tb;

architecture test of spi_tb is

  file file_RESULTS    : text;
  constant clk_period  : time := 30.0 ns;
  constant sclk_period : time := 320 ns;  -- 3.125 MHz

  signal clock      : std_logic                      := '0';
  signal sclk       : std_logic                      := '0';
  signal sclk_gated : std_logic                      := '0';
  signal sdat       : std_logic                      := '0';
  signal data       : std_logic_vector (31 downto 0) := (others => '0');
  signal valid      : std_logic                      := '0';

  signal en      : std_logic                      := '0';
  signal data_i  : std_logic_vector (31 downto 0) := x"5555aaaa";
  signal bit_cnt : integer range 0 to 31          := 31;
  signal timeout : std_logic                      := '0';


begin

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;

  proc_sclk : process
  begin
    wait for sclk_period/2.0;
    sclk <= '0';
    wait for sclk_period/2.0;
    sclk <= '1';
  end process;

  proc_en : process
  begin

    --------------------------------------------------------------------------------
    -- pattern 1
    --------------------------------------------------------------------------------

    wait for 1000 ns;
    data_i <= x"5555AAAA";

    wait until rising_edge(sclk);
    en <= '1';
    wait for sclk_period * 32;
    en <= '0';

    assert data = data_i severity error;

    --------------------------------------------------------------------------------
    -- pattern 2
    --------------------------------------------------------------------------------

    wait for 1000 ns;
    data_i <= x"AAAA5555";

    wait until rising_edge(sclk);
    en <= '1';
    wait for sclk_period * 32;
    en <= '0';

    assert data = data_i severity error;

    --------------------------------------------------------------------------------
    -- pattern 3
    --------------------------------------------------------------------------------

    wait for 1000 ns;
    data_i <= x"FFFF0000";

    wait until rising_edge(sclk);
    en <= '1';
    wait for sclk_period * 32;
    en <= '0';

    assert data = data_i severity error;

    --------------------------------------------------------------------------------
    -- pattern 4
    --------------------------------------------------------------------------------

    wait for 1000 ns;
    data_i <= x"0000FFFF";

    wait until rising_edge(sclk);
    en <= '1';
    wait for sclk_period * 32;
    en <= '0';

    assert data = data_i severity error;

    --------------------------------------------------------------------------------
    -- timeout
    --------------------------------------------------------------------------------

    wait for 1000 ns;
    data_i <= x"bbbbbbbb";

    wait until rising_edge(sclk);
    en <= '1';
    wait for sclk_period * 22;
    en <= '0';

    timeout <= '1';
    wait for 20000 ns;
    timeout <= '0';

    assert data = x"FFFFFFFF" severity error;

  end process;


  process (sclk_gated, timeout) is
  begin

    if (rising_edge(sclk_gated)) then
      sdat <= data_i(bit_cnt);
      if (bit_cnt > 0) then
        bit_cnt <= bit_cnt - 1;
      else
        bit_cnt <= 31;
      end if;
    end if;

    if (timeout = '1') then
      bit_cnt <= 31;
    end if;

  end process;

  sclk_gated <= sclk and en;

  spi_rx_1 : entity work.spi_rx
    port map (
      clock   => clock,
      sclk    => sclk_gated,
      sdat    => sdat,
      data_o  => data,
      valid_o => valid
      );

end test;
