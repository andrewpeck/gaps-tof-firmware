
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.math_real.uniform;
use ieee.math_real.floor;

entity trigger_mux_tb is
end trigger_mux_tb;

architecture tb of trigger_mux_tb is

  file file_RESULTS   : text;
  constant clk_period : time := 30.0 ns;
  constant sim_period : time := 40000 ns;

  signal clock                 : std_logic := '0';
  signal ext_trigger_i         : std_logic := '0';
  signal ext_trigger_en        : std_logic := '0';
  signal ext_trigger_active_hi : std_logic := '0';
  signal force_trig            : std_logic := '0';
  signal master_trigger        : std_logic := '0';
  signal dwrite_o              : std_logic := '0';
  signal trigger_o             : std_logic := '0';

begin

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;


  proc_inject : process
  begin

    ext_trigger_en <= '1';
    ext_trigger_active_hi <= '1';

    report "testing ext trigger";

    wait for 200.2 ns;
    ext_trigger_i <= '1';
    wait for 35 ns;
    ext_trigger_i <= '0';

    wait for 1 ns;
    assert dwrite_o = '0' report "ext trigger dwrite failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '1' report "ext trigger trigger assertion failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '0' report "ext trigger trigger deassertion failure" severity error;


    report "testing force trig";

    wait for 200   ns;
    wait until rising_edge(clock);
    force_trig <= '1';
    wait until rising_edge(clock);
    force_trig <= '0';

    wait for 1 ns;
    assert dwrite_o = '0' report "ERROR: force trigger dwrite failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '1' report "ERROR: force trigger trigger assertion failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '0' report "ERROR: force trigger trigger deassertion failure" severity error;

    report "testing ext trigger disable";

    wait for 200   ns;
    ext_trigger_en <= '0';
    wait until rising_edge(clock);
    ext_trigger_i <= '1';
    wait until rising_edge(clock);
    ext_trigger_i <= '0';

    wait for 1 ns;
    assert dwrite_o = '1' report "ERROR: ext trigger disable failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '0' report "ERROR: ext trigger disable failure" severity error;
    wait until rising_edge(clock);


    report "testing inverted external trigger";

    ext_trigger_en <= '0';
    wait for 200 ns;
    ext_trigger_active_hi <= '0';
    ext_trigger_i <= '1';
    wait for 1 ns;
    ext_trigger_en <= '1';
    wait until rising_edge(clock);
    ext_trigger_i <= '0';
    wait until rising_edge(clock);
    ext_trigger_i <= '1';

    wait for 1 ns;
    assert dwrite_o = '0' report "ERROR: inverted trigger dwrite failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '1' report "ERROR: inverted trigger trigger assertion failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '0' report "ERROR: inverted trigger trigger deassertion failure" severity error;

    report "testing master trigger";
    wait for 200   ns;
    wait until rising_edge(clock);
    master_trigger <= '1';
    wait until rising_edge(clock);
    master_trigger <= '0';

    wait for 1 ns;
    assert dwrite_o = '0' report "ERROR: master trigger dwrite failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '1' report "ERROR: master trigger trigger assertion failure" severity error;
    wait until rising_edge(clock);
    assert trigger_o = '0' report "ERROR: master trigger trigger deassertion failure" severity error;


    wait for 200   ns;
    std.env.finish;

  end process;

  trigger_mux_inst : entity work.trigger_mux
    generic map (
      TRIGGER_OS_MAX => 3 )
    port map (
      clock                 => clock,
      ext_trigger_i         => ext_trigger_i,
      ext_trigger_en        => ext_trigger_en,
      ext_trigger_active_hi => ext_trigger_active_hi,
      force_trig            => force_trig,
      master_trigger        => master_trigger,
      dwrite_o              => dwrite_o,
      trigger_o             => trigger_o);

end tb;
