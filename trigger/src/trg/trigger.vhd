library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.types_pkg.all;
use work.mt_types.all;
use work.constants.all;

entity trigger is
  port(

    clk : in std_logic;

    reset : in std_logic;

    single_hit_en_i : in std_logic := '1';

    -- this is an array of 25*8 = 200 thresholds, where each threshold is a 2
    -- bit value
    hits_i : in threshold_array_t;

    busy_i    : in std_logic;
    rb_busy_i : in std_logic_vector(NUM_RBS-1 downto 0);

    force_trigger_i : in std_logic;

    channel_select_o : out channel_bitmask_t;
    global_trigger_o : out std_logic;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    event_cnt_o      : out std_logic_vector (31 downto 0)

    );
end trigger;

architecture behavioral of trigger is

  signal global_trigger : std_logic := '0';

  -- flatten the 200 inputs from a threshold to just a bitmask meaning that a
  -- channel is either on or off
  signal single_hit_triggers : channel_bitmask_t := (others => '0');

  signal channels, channels_r : channel_bitmask_t := (others => '0');

  signal rb_triggers : std_logic_vector (NUM_RBS-1 downto 0);

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

  --------------------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------------------

  global_trigger <= or_reduce(rb_triggers);

  process (clk) is
  begin
    if (rising_edge(clk)) then

      channels   <= single_hit_triggers or repeat(force_trigger_i, channels'length);
      channels_r <= channels;

      for I in rb_triggers'range loop
        --rb_triggers(I) <= or_reduce(channels((I+1)*4-1 downto I*4));
        rb_triggers(I) <= or_reduce(channels);
      end loop;

    end if;
  end process;

--------------------------------------------------------------------------------
-- event counter:
--------------------------------------------------------------------------------

  -- delay by 1 clock to align with event count
  process (clk) is
  begin
    if (rising_edge(clk)) then
      channel_select_o <= channels_r;
      rb_triggers_o    <= rb_triggers;
      global_trigger_o <= global_trigger;
    end if;
  end process;

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset,
      global_trigger_i => global_trigger,
      event_count_o    => event_cnt_o
      );

end behavioral;
