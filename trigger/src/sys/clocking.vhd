
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity clocking is
  port(
    clock_i   : in  std_logic;
    clk100    : out std_logic;
    clk200    : out std_logic;
    clk125    : out std_logic;
    clk125_90 : out std_logic;
    locked    : out std_logic
    );
end clocking;

architecture structural of clocking is

  component mt_clk_wiz
    port (
      -- Clock out ports
      clk100    : out std_logic;
      clk200    : out std_logic;
      clk125    : out std_logic;
      clk125_90 : out std_logic;
      -- Status and control signals
      reset     : in  std_logic;
      locked    : out std_logic;
      -- Clock in ports
      clk_in1   : in  std_logic
      );
  end component;

begin

  clocking : mt_clk_wiz
    port map (
      -- Clock out ports
      clk100    => clk100,
      clk200    => clk200,
      clk125    => clk125,
      clk125_90 => clk125_90,
      -- Status and control signals
      reset     => '0',
      locked    => locked,
      -- Clock in ports
      clk_in1   => clock_i
      );

end structural;
