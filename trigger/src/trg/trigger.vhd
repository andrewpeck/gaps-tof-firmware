library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity trigger is
  port(

    clock : in std_logic;

    hits_i           : channel_array_t;
    triggers_o       : channel_array_t;
    global_trigger_o : std_logic

    );
end trigger;

architecture behavioral of trigger is

  signal triggers, triggers_r : channel_array_t;
  signal or_reduction         : std_logic_vector (NUM_RBS-1 downto 0) := (others => '0');

begin


  rbgen : for I in 0 to NUM_RBS-1 generate
  begin
    hitgen : for J in 0 to NUM_LT_CHANNELS-1 generate
    begin

      process (clock) is
      begin

        if (rising_edge(clock)) then
          triggers(I)(J) <= hits_i(I)(J);
        end if;

      end process;

    end generate;
  end generate;

  or_reduction_loop : for I in 0 to NUM_RBS-1 generate
  begin
    process (clock) is
    begin
      if (rising_edge(clock)) then
        or_reduction(I) <= reduce_or(triggers_i);
      end if;
    end process;
  end generate;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      global_trigger <= reduce_or(rb_ors);
      triggers_r     <= triggers;
      triggers_o     <= triggers_r;
    end if;
  end process;

end behavioral;
