library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity trigger is
  port(

    clk : in std_logic;

    single_hit_en_i  : in std_logic;

    hits_i           : in  channel_array_t;

    triggers_o       : out channel_array_t;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    global_trigger_o : out std_logic

    );
end trigger;

architecture behavioral of trigger is

  signal single_hit_triggers : channel_array_t;

  signal triggers, triggers_r : channel_array_t;
  signal rb_triggers          : rb_channel_array_t;

  signal rb_ors : std_logic_vector (NUM_RBS-1 downto 0)
    := (others => '0');

begin

  rb_triggers <= reshape(triggers);

  single_hit_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (single_hit_en_i='1') then
          single_hit_triggers(I) <= hits_i(I);
        else
          single_hit_triggers(I) <= '0';
        end if;
      end if;
    end process;
  end generate;

  or_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        rb_ors(I) <= or_reduce(rb_triggers(I));
      end if;
    end process;
  end generate;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      global_trigger_o <= or_reduce(rb_ors);

      -- delay by 1 clk to align with global trigger
      rb_triggers_o <= rb_ors;
      triggers_r    <= triggers;
      triggers_o    <= triggers_r;
    end if;
  end process;

end behavioral;
