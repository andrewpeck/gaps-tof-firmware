library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity trigger is
  port(

    clock : in std_logic;

    hits_i           : in  channel_array_t;
    triggers_o       : in  channel_array_t;
    global_trigger_o : out std_logic

    );
end trigger;

architecture behavioral of trigger is

  signal lt_hits_i : lt_channel_array_t;

  signal triggers, triggers_r : lt_channel_array_t;

  signal or_reduction : std_logic_vector (NUM_LTS-1 downto 0) := (others => '0');

begin

  lt_hits_i <= reshape(hits_i);

  rbgen : for I in 0 to NUM_RBS-1 generate
  begin
    hitgen : for J in 0 to NUM_LT_CHANNELS-1 generate
    begin

      process (clock) is
      begin
        if (rising_edge(clock)) then
          triggers(I)(J) <= lt_hits_i(I)(J);
        end if;
      end process;

    end generate;
  end generate;

  or_reduction_loop : for I in 0 to NUM_RBS-1 generate
  begin
    process (clock) is
    begin
      if (rising_edge(clock)) then
        or_reduction(I) <= or_reduce(triggers(I));
      end if;
    end process;
  end generate;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      global_trigger_o <= or_reduce(rb_ors);

      -- delay by 1 clock to align with global trigger
      triggers_r <= triggers;
      triggers_o <= triggers_r;
    end if;
  end process;

end behavioral;
