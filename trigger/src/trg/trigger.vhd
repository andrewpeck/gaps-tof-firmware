library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity trigger is
  port(

    clk : in std_logic;

    reset : in std_logic;

    single_hit_en_i : in std_logic := '1';
    bool_trg_en_i   : in std_logic := '1';

    hits_i : in threshold_array_t;

    busy_i : in std_logic;

    force_trigger_i : in std_logic;

    triggers_o       : out channel_bitmask_t;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    global_trigger_o : out std_logic;

    event_cnt_o : out std_logic_vector (31 downto 0)

    );
end trigger;

architecture behavioral of trigger is

  signal global_trigger : std_logic := '0';

  signal single_hit_triggers  : channel_bitmask_t := (others => '0');
  signal bool_triggers        : channel_bitmask_t := (others => '0');
  signal triggers, triggers_r : channel_bitmask_t := (others => '0');

  --signal rb_triggers          : rb_channel_bitmask_t;

  signal rb_ors : std_logic_vector (NUM_RBS-1 downto 0)
    := (others => '0');

begin

  single_hit_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (single_hit_en_i = '1' and hits_i(I) /= "00") then
          single_hit_triggers(I) <= '1';
        else
          single_hit_triggers(I) <= '0';
        end if;
      end if;
    end process;
  end generate;

  -- process (clk) is
  -- begin
  --   if (rising_edge(clk)) then
  --     if (bool_trg_en_i = '1') then

  --         bool_triggers(I) <= '0';

  --     else
  --       for I in 0 to hits_i'length-1 loop
  --         bool_triggers(I) <= '0';
  --       end loop;
  --     end if;
  --   end if;
  -- end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      triggers <= single_hit_triggers or bool_triggers;
    end if;
  end process;

  -- reshape the data type
  -- rb_triggers <= reshape(triggers);

  or_gen : for I in 0 to rb_ors'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        rb_ors(I) <= force_trigger_i;   -- or or_reduce(rb_triggers(I));
      end if;
    end process;
  end generate;

  global_trigger <= or_reduce(rb_ors);

  process (clk) is
  begin
    if (rising_edge(clk)) then
      global_trigger_o <= global_trigger;

      -- delay by 1 clk to align with global trigger
      rb_triggers_o <= rb_ors;
      triggers_r    <= triggers;
      triggers_o    <= triggers_r;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- event counter:
  --------------------------------------------------------------------------------

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset,
      global_trigger_i => global_trigger,
      event_count_o    => event_cnt_o
      );

end behavioral;
