library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity adc_tb is
end adc_tb;

architecture tb of adc_tb is

  constant clk_period : time      := 30.0 ns;
  constant sim_period : time      := 100000000.0 ns;

  signal clock        : std_logic := '0';
  signal reset        : std_logic := '1';

  signal calibration : std_logic_vector(15 downto 0) := (others => '0');
  signal vccpint     : std_logic_vector(15 downto 0) := (others => '0');
  signal vccpaux     : std_logic_vector(15 downto 0) := (others => '0');
  signal vccoddr     : std_logic_vector(15 downto 0) := (others => '0');
  signal temp        : std_logic_vector(15 downto 0) := (others => '0');
  signal vccint      : std_logic_vector(15 downto 0) := (others => '0');
  signal vccaux      : std_logic_vector(15 downto 0) := (others => '0');
  signal vccbram     : std_logic_vector(15 downto 0) := (others => '0');

begin

  proc_reset : process
  begin
    wait for 200 ns;
    reset <= '0';
  end process;

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;

  fi_clk : process
  begin
    wait for sim_period;
    std.env.finish;
  end process;

  adc_inst : entity work.adc
    port map (
      clock       => clock,
      reset       => reset,
      calibration => calibration,
      vccpint     => vccpint,
      vccpaux     => vccpaux,
      vccoddr     => vccoddr,
      temp        => temp,
      vccint      => vccint,
      vccaux      => vccaux,
      vccbram     => vccbram
      );

end tb;
