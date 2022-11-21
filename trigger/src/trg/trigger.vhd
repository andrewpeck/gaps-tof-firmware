library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.types_pkg.all;
use work.mt_types.all;
use work.constants.all;
use work.components.all;

entity trigger is
  port(

    clk : in std_logic;

    reset : in std_logic;

    single_hit_en_i : in std_logic := '1';
    ucla_trig_en_i  : in std_logic := '1';

    all_triggers_are_global : in std_logic := '1';

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

  signal dead          : std_logic                      := '0';
  constant deadcnt_max : integer                        := 31;
  signal deadcnt       : integer range 0 to deadcnt_max := 0;

  --------------------------------------------------------------------------------
  -- UCLA trigger
  --------------------------------------------------------------------------------

  signal ucla_trigger : std_logic := '0';

  signal top_1_ab, bottom_1_ab : std_logic;
  signal top_2_ab, bottom_2_ab : std_logic;
  signal top_3_ab, bottom_3_ab : std_logic;
  signal top_4_ab, bottom_4_ab : std_logic;

  --------------------------------------------------------------------------------
  -- Global trigger
  --------------------------------------------------------------------------------

  signal global_trigger, global_trigger_r : std_logic := '0';

  -- flatten the 200 inputs from a threshold to just a bitmask meaning that a
  -- channel is either on or off
  signal hitmask : channel_bitmask_t := (others => '0');

  signal per_channel_triggers : channel_bitmask_t := (others => '0');

  constant NUM_CHANNELS : integer := per_channel_triggers'length;

  signal rb_triggers, rb_triggers_r : std_logic_vector (NUM_RBS-1 downto 0);

begin

  --------------------------------------------------------------------------------
  -- Turn the level triggers into on/off bits
  --------------------------------------------------------------------------------

  single_hit_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (hits_i(I) /= "00") then
          hitmask(I) <= '1';
        else
          hitmask(I) <= '0';
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------------
  -- UCLA trigger
  --
  -- 5 top paddles, 4 bottom paddles
  --
  -- RB1 (tof-rb51) is connected to the bottom paddles (ch0 to bottom
  -- paddle 1 side A, ch1 to bottom paddle 1 side B, ch2 to bottom
  -- paddle 2 side A, ch3 to bottom paddle 2 side B and so on).
  --
  -- RB2 (tof-rb52) is connected to the top paddles (ch0 to top paddle
  -- 1 side A, ch1 to top paddle 1 side B, ch2 to top paddle 2 side A,
  -- ch3 to top paddle 2 side B and so on).
  --
  -- LTB is connected to the low gains:
  -- ch0 to bottom paddle 1 A side,
  -- ch1 to bottom paddle 1 B side,
  -- ch7 to top paddle 1 side A,
  -- ch8 to top paddle 1 side B, and so on
  --
  --------------------------------------------------------------------------------

  ila_trigger_inst : ila_trigger
    port map (
      clk    => clk,
      probe0 => x"0" & top_4_ab & top_3_ab & top_2_ab & top_1_ab,
      probe1 => x"0" & bottom_4_ab & bottom_3_ab & bottom_2_ab & bottom_1_ab,
      probe2 => global_trigger & dead & ucla_trigger,
      probe3 => event_cnt_o
      );

  --------------------------------------------------------------------------------
  -- UCLA Cosmic Trigger
  --------------------------------------------------------------------------------

  bottom_1_ab <= hitmask(0);
  bottom_2_ab <= hitmask(1);
  bottom_3_ab <= hitmask(2);
  bottom_4_ab <= hitmask(3);

  top_1_ab    <= hitmask(4);
  top_2_ab    <= hitmask(5);
  top_3_ab    <= hitmask(6);
  top_4_ab    <= hitmask(7);

  process (clk) is
  begin
    if (rising_edge(clk)) then
      -- trigger on bottom paddle 1 (ch0 and ch1 on LTB) and top paddle 1 (ch7 and ch8 on LTB).
      ucla_trigger <= (bottom_1_ab and top_1_ab);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Source OR
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      for I in 0 to per_channel_triggers'length-1 loop
        per_channel_triggers(I) <= not dead and (force_trigger_i or
                                                 (hitmask(I) and single_hit_en_i) or
                                                 (ucla_trigger and ucla_trig_en_i));
      end loop;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Outputs
  --------------------------------------------------------------------------------

  rb_trig_gen : for I in rb_triggers'range generate
  begin
    rb_triggers(I) <= or_reduce(per_channel_triggers((I+1)*4-1 downto I*4));
  end generate;

  global_trigger <= or_reduce(per_channel_triggers);

  --------------------------------------------------------------------------------
  -- event counter:
  --------------------------------------------------------------------------------

  -- delay by 1 clock to align with event count
  process (clk) is
  begin
    if (rising_edge(clk)) then
      global_trigger_r <= not dead and global_trigger;
      rb_triggers_r    <= rb_triggers;

      channel_select_o <= per_channel_triggers;
      rb_triggers_o    <= rb_triggers_r or repeat(global_trigger_r and all_triggers_are_global, rb_triggers_o'length);
      global_trigger_o <= global_trigger_r;
    end if;
  end process;

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset,
      global_trigger_i => global_trigger_r,
      event_count_o    => event_cnt_o
      );

  --------------------------------------------------------------------------------
  -- Deadtime
  --
  -- this should I guess be replaced with busy logic from the sili
  -- but just put some simple stupid deadtime in for now
  --
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (dead = '0' and global_trigger = '1') then
        deadcnt <= deadcnt_max;
        dead    <= '1';
      elsif (deadcnt > 0) then
        deadcnt <= deadcnt - 1;
        dead    <= '1';
      elsif (deadcnt = 0) then
        dead <= '0';
      end if;
    end if;
  end process;

end behavioral;
