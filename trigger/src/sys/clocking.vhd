
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity clocking is
  port(
    clock_i : in  std_logic;
    clk100  : out std_logic;
    clk200  : out std_logic;
    locked  : out std_logic
    );
end clocking;

architecture structural of clocking is

  component mt_clk_wiz
    port
      (                                 -- Clock in ports
        -- Clock out ports
        clk_out1 : out std_logic;
        clk_out2 : out std_logic;
        -- Status and control signals
        reset    : in  std_logic;
        locked   : out std_logic;
        clk_in1  : in  std_logic
        );
  end component;

begin

  clocking : mt_clk_wiz
    port map (
      -- Clock out ports
      clk_out1 => clk100,
      clk_out2 => clk200,
      -- Status and control signals
      reset    => '0',
      locked   => locked,
      -- Clock in ports
      clk_in1  => clock_i
      );

end structural;
