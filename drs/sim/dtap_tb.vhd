library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dtap_tb is
end dtap_tb;

architecture test of dtap_tb is

  constant WIDTH : natural := 16;
  constant MHZ   : natural := 33333333;
  constant DIV   : natural := 100;

  file file_RESULTS    : text;
  constant clk_period  : time := 30.0 ns;
  constant dtap_period : time := 2000 ns;  -- 1us = 1MHz

  signal clock      : std_logic;
  signal drs_dtap_i : std_logic;
  signal dtap_cnt_o : std_logic_vector (WIDTH-1 downto 0);

begin

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;

  proc_dtap : process
  begin
    wait for dtap_period/2.0;
    drs_dtap_i <= '0';
    wait for dtap_period/2.0;
    drs_dtap_i <= '1';
  end process;

  dtap_inst : entity work.dtap
    generic map (
      WIDTH => WIDTH,
      MHZ   => MHZ,
      DIV   => DIV)
    port map (
      clock      => clock,
      drs_dtap_i => drs_dtap_i,
      dtap_cnt_o => dtap_cnt_o
      );

  proc_out : process
  begin
    wait until dtap_cnt_o'event;
    write(output, "output = " & integer'image(to_integer(unsigned(dtap_cnt_o))) & LF);
  end process;
end test;
