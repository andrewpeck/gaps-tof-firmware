library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.types_pkg.all;
use work.mt_types.all;
use work.constants.all;
use work.components.all;

-- Panel mapping: https://docs.google.com/spreadsheets/d/1i41fsmLf7IjfYbr1coTo9V4uk3t1GXAGgt0aOeCkeeA/edit#gid=0

entity trigger is
  port(

    clk : in std_logic;

    reset : in std_logic;

    event_cnt_reset : in std_logic;

    single_hit_en_i : in std_logic := '0';

    trig_mask_a : in std_logic_vector (31 downto 0);

    trig_mask_b : in std_logic_vector (31 downto 0);

    all_triggers_are_global : in std_logic := '1';

    -- this is an array of 25*8 = 200 thresholds, where each threshold is a 2
    -- bit value
    hits_i : in threshold_array_t;

    busy_i    : in std_logic;
    rb_busy_i : in std_logic_vector(NUM_RBS-1 downto 0);

    force_trigger_i : in std_logic;

    channel_select_o : out channel_bitmask_t;
    global_trigger_o : out std_logic;
    lost_trigger_o   : out std_logic;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    event_cnt_o      : out std_logic_vector (31 downto 0)

    );
end trigger;

architecture behavioral of trigger is

  constant DEADCNT_MAX : integer                        := 31;
  signal dead          : std_logic                      := '0';
  signal deadcnt       : integer range 0 to DEADCNT_MAX := 0;

  signal programmable_trigger : std_logic := '0';

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
  -- ILA
  --------------------------------------------------------------------------------

  ila_trigger_inst : ila_trigger
    port map (
      clk    => clk,
      probe0 => (others => '0'),
      probe1 => (others => '0'),
      probe2 => busy_i & global_trigger & dead & programmable_trigger,
      probe3 => event_cnt_o,
      probe4 => hitmask
      );

  --------------------------------------------------------------------------------
  -- Programmable Trigger
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      programmable_trigger <= or_reduce(hitmask(31 downto 0) and trig_mask_a) and
                              or_reduce(hitmask(31 downto 0) and trig_mask_b);
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
                                                 programmable_trigger);
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
      lost_trigger_o   <= busy_i and global_trigger;
      global_trigger_r <= not busy_i and not dead and global_trigger;
      rb_triggers_r    <= rb_triggers;

      channel_select_o <= per_channel_triggers;
      rb_triggers_o    <= repeat (not busy_i, rb_triggers_o'length) and (rb_triggers_r or repeat(global_trigger_r and all_triggers_are_global, rb_triggers_o'length));
      global_trigger_o <= global_trigger_r;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Counter
  --------------------------------------------------------------------------------

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset or event_cnt_reset,
      global_trigger_i => global_trigger_r,
      event_count_o    => event_cnt_o
      );

  --------------------------------------------------------------------------------
  -- Deadtime
  --------------------------------------------------------------------------------
  -- Enforce some minimal deadtime between triggers,
  -- give the SiLi some time to respond
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (dead = '0' and global_trigger = '1') then
        deadcnt <= DEADCNT_MAX;
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
