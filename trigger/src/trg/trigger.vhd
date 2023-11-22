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
  generic (DEBUG : boolean := true);
  port(

    clk : in std_logic;

    reset : in std_logic;

    event_cnt_reset : in std_logic;

    any_hit_trigger_is_global : in std_logic;
    track_trigger_is_global   : in std_logic;

    any_hit_trigger_prescale : in std_logic_vector (31 downto 0);
    track_trigger_prescale   : in std_logic_vector (31 downto 0);

    hit_thresh : in std_logic_vector (1 downto 0);

    trig_mask_a : in std_logic_vector (31 downto 0);

    trig_mask_b : in std_logic_vector (31 downto 0);

    read_all_channels : in std_logic := '1';

    -- this is an array of 25*8 = 200 thresholds, where each threshold is a 2
    -- bit value
    hits_i : in  threshold_array_t;
    hits_o : out threshold_array_t;

    -- trigger parameters
    ssl_trig_top_bot_en       : in std_logic;
    ssl_trig_topedge_bot_en   : in std_logic;
    ssl_trig_top_botedge_en   : in std_logic;
    ssl_trig_topmid_botmid_en : in std_logic;

    gaps_trigger_en  : in std_logic;
    require_beta     : in std_logic;
    inner_tof_thresh : in std_logic_vector (7 downto 0);
    outer_tof_thresh : in std_logic_vector (7 downto 0);
    total_tof_thresh : in std_logic_vector (7 downto 0);

    busy_i      : in std_logic;
    rb_busy_i   : in std_logic_vector(NUM_RBS-1 downto 0);
    rb_window_i : in std_logic_vector(4 downto 0);

    force_trigger_i : in std_logic;

    trig_sources_o   : out std_logic_vector(15 downto 0) := (others => '0');
    pre_trigger_o    : out std_logic;
    global_trigger_o : out std_logic := '0';
    lost_trigger_o   : out std_logic;
    rb_trigger_o     : out std_logic;
    rb_ch_bitmap_o   : out std_logic_vector (NUM_RBS*8-1 downto 0) := (others => '0');
    event_cnt_o      : out std_logic_vector (31 downto 0)
    );
end trigger;

architecture behavioral of trigger is

  -- t0: + hits_i arrives
  --     + gets async remapped to different stations
  --
  -- t1: + FF onto hit/beta/veto
  --
  -- t2: + FF count # of hits -> inner/outer_tof_thresh  } -> GAPS trigger
  --     + OR(beta)                                      }
  --
  -- t3: + FF trigger sources onto pretrigger
  --
  -- t4: + global_trigger + event counter output

  -- constant should be # of clocks from hits_i to pretrigger
  constant TRIG_LATENCY : integer := 4;
  type hits_dlyline_t is array (integer range <>) of threshold_array_t;
  signal hits_dly       : hits_dlyline_t (TRIG_LATENCY-3 downto 0) := (others => (others => (others => '0')));

  constant HIT_BITMAP_LATENCY : integer := TRIG_LATENCY-3;
  type hit_bitmap_dlyline_t is array (integer range <>) of channel_bitmask_t;
  signal hit_bitmap_dly       : hit_bitmap_dlyline_t (HIT_BITMAP_LATENCY-1 downto 0);

  constant DEADCNT_MAX : integer                        := 31;
  signal dead          : std_logic                      := '0';
  signal deadcnt       : integer range 0 to DEADCNT_MAX := 0;

  signal ssl_trig_top_bot       : std_logic := '0';
  signal ssl_trig_topedge_bot   : std_logic := '0';
  signal ssl_trig_top_botedge   : std_logic := '0';
  signal ssl_trig_topmid_botmid : std_logic := '0';

  signal programmable_trigger : std_logic := '0';
  signal gaps_trigger         : std_logic := '0';
  signal track_trigger        : std_logic := '0';
  signal any_trigger          : std_logic := '0';

  --------------------------------------------------------------------------------
  -- Detector Mapping
  --------------------------------------------------------------------------------

  constant NONE : std_logic_vector (1 downto 0) := "00";
  constant HIT  : std_logic_vector (1 downto 0) := "01";
  constant BETA : std_logic_vector (1 downto 0) := "10";
  constant VETO : std_logic_vector (1 downto 0) := "11";

  constant N_UMBRELLA    : integer := 48;
  constant N_CUBE_BOT    : integer := 12;
  constant N_CUBE        : integer := 44;
  constant N_CORTINA     : integer := 52;
  constant N_CUBE_CORNER : integer := 4;

  constant N_OUTER_TOF : integer := N_UMBRELLA + N_CORTINA;
  constant N_INNER_TOF : integer := N_CUBE_CORNER + N_CUBE + N_CUBE_BOT;

  type hit_array_t is array (integer range <>)
    of std_logic_vector(1 downto 0);

  signal cube        : hit_array_t(N_CUBE-1 downto 0);
  signal cube_bot    : hit_array_t(N_CUBE_BOT-1 downto 0);
  signal cube_corner : hit_array_t(N_CUBE_CORNER-1 downto 0);
  signal umbrella    : hit_array_t(N_UMBRELLA-1 downto 0);
  signal cortina     : hit_array_t(N_CORTINA-1 downto 0);

  signal cube_hit, cube_beta               : std_logic_vector(N_CUBE-1 downto 0);
  signal cube_bot_hit, cube_bot_beta       : std_logic_vector(N_CUBE_BOT-1 downto 0);
  signal cube_corner_hit, cube_corner_beta : std_logic_vector(N_CUBE_CORNER-1 downto 0);
  signal umbrella_hit, umbrella_beta       : std_logic_vector(N_UMBRELLA-1 downto 0);
  signal cortina_hit, cortina_beta         : std_logic_vector(N_CORTINA-1 downto 0);
  signal inner_tof_hit                     : std_logic_vector(N_INNER_TOF-1 downto 0);
  signal inner_tof_beta                    : std_logic_vector(N_INNER_TOF-N_CUBE_BOT-N_CUBE_CORNER-1 downto 0);
  signal outer_tof_hit, outer_tof_beta     : std_logic_vector(N_OUTER_TOF-1 downto 0);

  signal or_inner_tof_beta : std_logic;
  signal or_outer_tof_beta : std_logic;

  signal any_hit_trigger_en    : std_logic;
  signal any_hit_trigger_urand : std_logic_vector (31 downto 0) := (others => '0');

  signal track_trigger_en    : std_logic;
  signal track_trigger_urand : std_logic_vector (31 downto 0) := (others => '0');

  signal trig_sources        : std_logic_vector(15 downto 0) := (others => '0');
  signal trig_sources_reg    : std_logic_vector(15 downto 0) := (others => '0');
  signal pedestal_trig       : std_logic;
  signal pedestal_trig_latch : std_logic := '0';
  signal rb_trigger          : std_logic := '0';

  signal cube_cnts        : integer range 0 to N_CUBE;
  signal cube_bot_cnts    : integer range 0 to N_CUBE_BOT;
  signal cube_corner_cnts : integer range 0 to N_CUBE_CORNER;
  signal umbrella_cnts    : integer range 0 to N_UMBRELLA;
  signal cortina_cnts     : integer range 0 to N_CORTINA;
  signal inner_tof_cnts   : integer range 0 to N_INNER_TOF;
  signal outer_tof_cnts   : integer range 0 to N_OUTER_TOF;
  signal total_tof_cnts   : integer range 0 to N_OUTER_TOF + N_INNER_TOF;

  signal inner_tof_over_thresh : std_logic := '0';
  signal outer_tof_over_thresh : std_logic := '0';
  signal total_tof_over_thresh : std_logic := '0';

  function map_beta (d : hit_array_t)
    return std_logic_vector is
    variable q : std_logic_vector(d'range);
  begin
    q := (others => '0');
    for I in d'range loop
      if (d(I) = BETA) then
        q(I) := '1';
      end if;
    end loop;
    return q;
  end;

  function map_anyhit (d : hit_array_t)
    return std_logic_vector is
    variable q : std_logic_vector(d'range);
  begin
    q := (others => '0');
    for I in d'range loop
      if (d(I) /= NONE) then
        q(I) := '1';
      end if;
    end loop;
    return q;
  end;

  --------------------------------------------------------------------------------
  -- Global trigger
  --------------------------------------------------------------------------------

  signal pre_trigger : std_logic := '0';

  -- flatten the 200 inputs from a threshold to just a bitmask meaning that a
  -- channel is either on or off
  signal hit_bitmap : channel_bitmask_t := (others => '0');

  -- there are 200 LT channels as inputs, and 400 RB channels as outputs
  -- this is because each LT channel is the AND of two paddle ends, which are read
  -- separately by the RBs
  --
  -- there will be some non-trivial mapping where each RB paddle trigger is sourced by
  -- some LTB channel, and each LTB channel corresponds to 2 different RB channels

  signal rb_ch_bitmap     : std_logic_vector (NUM_RBS*8-1 downto 0);
  signal rb_ch_integrated : std_logic_vector (NUM_RBS*8-1 downto 0);

  --------------------------------------------------------------------------------
  -- misc
  --------------------------------------------------------------------------------

  function get_hits_from_slot (hits : std_logic_vector;
                               dsi  : integer;
                               slot : integer)
    return std_logic_vector is
    variable index : integer;
  begin
    -- 8 channels per connector
    -- 5 connectors per DSI
    -- 5 DSIs
    index := (dsi-1)*5 + (slot-1);
    return hits(8*(index+1)-1 downto 8*index);
  end;

begin

  --------------------------------------------------------------------------------
  -- Turn the level triggers into on/off bits
  --------------------------------------------------------------------------------

  any_hit_trigger_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (unsigned(hits_i(I)) > unsigned(hit_thresh)) then
          hit_bitmap(I) <= '1';
        else
          hit_bitmap(I) <= '0';
        end if;
      end if;
    end process;
  end generate;

  --------------------------------------------------------------------------------
  -- ILA
  --------------------------------------------------------------------------------

  debug_gen : if (DEBUG) generate
    ila_trigger_inst : ila_trigger
      port map (
        clk                => clk,
        probe0(0)          => pre_trigger,
        probe0(1)          => global_trigger_o,
        probe0(7 downto 2) => (others => '0'),
        probe1(7 downto 0) => (others => '0'),
        probe2             => busy_i & pre_trigger & dead & programmable_trigger,
        probe3             => event_cnt_o,
        probe4             => hit_bitmap
        );
  end generate;

  --------------------------------------------------------------------------------
  -- Gaps Trigger
  --------------------------------------------------------------------------------

  inner_tof_over_thresh <= '1' when (inner_tof_cnts >= to_integer(unsigned(inner_tof_thresh))) else '0';
  outer_tof_over_thresh <= '1' when (outer_tof_cnts >= to_integer(unsigned(outer_tof_thresh))) else '0';
  total_tof_over_thresh <= '1' when (total_tof_cnts >= to_integer(unsigned(total_tof_thresh))) else '0';

  gaps_trigger <= gaps_trigger_en and
                  (not require_beta or or_inner_tof_beta) and
                  (not require_beta or or_outer_tof_beta) and
                  inner_tof_over_thresh and
                  outer_tof_over_thresh and
                  total_tof_over_thresh;

  track_trigger <= '1' when (track_trigger_en = '1' and inner_tof_cnts >= 1 and outer_tof_cnts >= 1) else '0';

  any_trigger <= (or_reduce(hit_bitmap) and any_hit_trigger_en);

  --------------------------------------------------------------------------------
  -- Counters
  --------------------------------------------------------------------------------

  cube_cnt : entity work.count1s
    generic map (SIZE => cube_hit'length)
    port map (clock   => clk, d => cube_hit, cnt => cube_cnts);
  cube_bot_cnt : entity work.count1s
    generic map (SIZE => cube_bot_hit'length)
    port map (clock   => clk, d => cube_bot_hit, cnt => cube_bot_cnts);
  umbrella_cnt : entity work.count1s
    generic map (SIZE => umbrella_hit'length)
    port map (clock   => clk, d => umbrella_hit, cnt => umbrella_cnts);
  cortina_cnt : entity work.count1s
    generic map (SIZE => cortina_hit'length)
    port map (clock   => clk, d => cortina_hit, cnt => cortina_cnts);
  inner_tof_cnt : entity work.count1s
    generic map (SIZE => inner_tof_hit'length)
    port map (clock   => clk, d => inner_tof_hit, cnt => inner_tof_cnts);
  outer_tof_cnt : entity work.count1s
    generic map (SIZE => outer_tof_hit'length)
    port map (clock   => clk, d => outer_tof_hit, cnt => outer_tof_cnts);

  total_tof_cnts <= outer_tof_cnts + inner_tof_cnts;

  --------------------------------------------------------------------------------
  -- Input mapping
  --------------------------------------------------------------------------------

  -- Just to be clear, the "GAPS" trigger requires at least one hit in the outer
  -- TOF that satisfies BETA and at least one hit in the inner TOF that satisfies
  -- BETA, plus at least 8 hits total, of which at least 3 have to be in the inner
  -- TOF and 3 have to be in the outer TOF.

  -- The slides says "Umbrella" and "Cube", but you should interpret that as:
  -- "Outer TOF" and "Inner TOF".

  process (clk) is
  begin
    if (rising_edge(clk)) then

      cube_beta <= map_beta(cube);
      cube_hit  <= map_anyhit(cube);

      cube_bot_beta <= map_beta(cube_bot);
      cube_bot_hit  <= map_anyhit(cube_bot);

      cube_corner_beta <= map_beta(cube_corner);
      cube_corner_hit  <= map_anyhit(cube_corner);

      umbrella_beta <= map_beta(umbrella);
      umbrella_hit  <= map_anyhit(umbrella);

      cortina_beta <= map_beta(cortina);
      cortina_hit  <= map_anyhit(cortina);

    end if;
  end process;

  inner_tof_hit  <= cube_hit & cube_bot_hit & cube_corner_hit;
  inner_tof_beta <= cube_beta;  -- exclude the bottom and corner from the beta test
  outer_tof_hit  <= umbrella_hit & cortina_hit;
  outer_tof_beta <= umbrella_beta & cortina_beta;

  -- or reduce and delay by 1 clock to align with hit counters
  process (clk) is
  begin
    if (rising_edge(clk)) then
      or_inner_tof_beta <= or_reduce(inner_tof_beta);
      or_outer_tof_beta <= or_reduce(outer_tof_beta);
    end if;
  end process;

  process (hits_i) is
  begin

    --START: autoinsert mapping

    cube(0)  <= hits_i(61);  -- panel= 1 paddle=  1 station=cube; LTB DSI2 J3 Ch11 Bit5
    cube(1)  <= hits_i(60);  -- panel= 1 paddle=  2 station=cube; LTB DSI2 J3 Ch 9 Bit4
    cube(2)  <= hits_i(59);  -- panel= 1 paddle=  3 station=cube; LTB DSI2 J3 Ch 7 Bit3
    cube(3)  <= hits_i(58);  -- panel= 1 paddle=  4 station=cube; LTB DSI2 J3 Ch 5 Bit2
    cube(4)  <= hits_i(57);  -- panel= 1 paddle=  5 station=cube; LTB DSI2 J3 Ch 3 Bit1
    cube(5)  <= hits_i(56);  -- panel= 1 paddle=  6 station=cube; LTB DSI2 J3 Ch 1 Bit0
    cube(6)  <= hits_i(127);  -- panel= 1 paddle=  7 station=cube; LTB DSI4 J1 Ch16 Bit7
    cube(7)  <= hits_i(126);  -- panel= 1 paddle=  8 station=cube; LTB DSI4 J1 Ch14 Bit6
    cube(8)  <= hits_i(125);  -- panel= 1 paddle=  9 station=cube; LTB DSI4 J1 Ch12 Bit5
    cube(9)  <= hits_i(124);  -- panel= 1 paddle= 10 station=cube; LTB DSI4 J1 Ch10 Bit4
    cube(10) <= hits_i(123);  -- panel= 1 paddle= 11 station=cube; LTB DSI4 J1 Ch 8 Bit3
    cube(11) <= hits_i(122);  -- panel= 1 paddle= 12 station=cube; LTB DSI4 J1 Ch 6 Bit2
    cube(12) <= hits_i(62);  -- panel= 3 paddle= 25 station=cube; LTB DSI2 J3 Ch14 Bit6
    cube(13) <= hits_i(63);  -- panel= 3 paddle= 26 station=cube; LTB DSI2 J3 Ch16 Bit7
    cube(14) <= hits_i(69);  -- panel= 3 paddle= 27 station=cube; LTB DSI2 J4 Ch12 Bit5
    cube(15) <= hits_i(68);  -- panel= 3 paddle= 28 station=cube; LTB DSI2 J4 Ch10 Bit4
    cube(16) <= hits_i(67);  -- panel= 3 paddle= 29 station=cube; LTB DSI2 J4 Ch 8 Bit3
    cube(17) <= hits_i(66);  -- panel= 3 paddle= 30 station=cube; LTB DSI2 J4 Ch 6 Bit2
    cube(18) <= hits_i(65);  -- panel= 3 paddle= 31 station=cube; LTB DSI2 J4 Ch 4 Bit1
    cube(19) <= hits_i(64);  -- panel= 3 paddle= 32 station=cube; LTB DSI2 J4 Ch 2 Bit0
    cube(20) <= hits_i(92);  -- panel= 4 paddle= 33 station=cube; LTB DSI3 J2 Ch10 Bit4
    cube(21) <= hits_i(91);  -- panel= 4 paddle= 34 station=cube; LTB DSI3 J2 Ch 8 Bit3
    cube(22) <= hits_i(93);  -- panel= 4 paddle= 35 station=cube; LTB DSI3 J2 Ch12 Bit5
    cube(23) <= hits_i(90);  -- panel= 4 paddle= 36 station=cube; LTB DSI3 J2 Ch 6 Bit2
    cube(24) <= hits_i(94);  -- panel= 4 paddle= 37 station=cube; LTB DSI3 J2 Ch14 Bit6
    cube(25) <= hits_i(89);  -- panel= 4 paddle= 38 station=cube; LTB DSI3 J2 Ch 4 Bit1
    cube(26) <= hits_i(95);  -- panel= 4 paddle= 39 station=cube; LTB DSI3 J2 Ch16 Bit7
    cube(27) <= hits_i(88);  -- panel= 4 paddle= 40 station=cube; LTB DSI3 J2 Ch 2 Bit0
    cube(28) <= hits_i(121);  -- panel= 5 paddle= 41 station=cube; LTB DSI4 J1 Ch 4 Bit1
    cube(29) <= hits_i(120);  -- panel= 5 paddle= 42 station=cube; LTB DSI4 J1 Ch 2 Bit0
    cube(30) <= hits_i(114);  -- panel= 5 paddle= 43 station=cube; LTB DSI3 J5 Ch 6 Bit2
    cube(31) <= hits_i(115);  -- panel= 5 paddle= 44 station=cube; LTB DSI3 J5 Ch 8 Bit3
    cube(32) <= hits_i(116);  -- panel= 5 paddle= 45 station=cube; LTB DSI3 J5 Ch10 Bit4
    cube(33) <= hits_i(117);  -- panel= 5 paddle= 46 station=cube; LTB DSI3 J5 Ch12 Bit5
    cube(34) <= hits_i(118);  -- panel= 5 paddle= 47 station=cube; LTB DSI3 J5 Ch14 Bit6
    cube(35) <= hits_i(119);  -- panel= 5 paddle= 48 station=cube; LTB DSI3 J5 Ch16 Bit7
    cube(36) <= hits_i(148);  -- panel= 6 paddle= 49 station=cube; LTB DSI4 J4 Ch10 Bit4
    cube(37) <= hits_i(147);  -- panel= 6 paddle= 50 station=cube; LTB DSI4 J4 Ch 8 Bit3
    cube(38) <= hits_i(149);  -- panel= 6 paddle= 51 station=cube; LTB DSI4 J4 Ch12 Bit5
    cube(39) <= hits_i(146);  -- panel= 6 paddle= 52 station=cube; LTB DSI4 J4 Ch 6 Bit2
    cube(40) <= hits_i(150);  -- panel= 6 paddle= 53 station=cube; LTB DSI4 J4 Ch14 Bit6
    cube(41) <= hits_i(145);  -- panel= 6 paddle= 54 station=cube; LTB DSI4 J4 Ch 4 Bit1
    cube(42) <= hits_i(151);  -- panel= 6 paddle= 55 station=cube; LTB DSI4 J4 Ch16 Bit7
    cube(43) <= hits_i(144);  -- panel= 6 paddle= 56 station=cube; LTB DSI4 J4 Ch 2 Bit0

    umbrella(0)  <= hits_i(5);  -- panel= 7 paddle= 61 station=umbrella; LTB DSI1 J1 Ch11 Bit5
    umbrella(1)  <= hits_i(4);  -- panel= 7 paddle= 62 station=umbrella; LTB DSI1 J1 Ch 9 Bit4
    umbrella(2)  <= hits_i(3);  -- panel= 7 paddle= 63 station=umbrella; LTB DSI1 J1 Ch 7 Bit3
    umbrella(3)  <= hits_i(2);  -- panel= 7 paddle= 64 station=umbrella; LTB DSI1 J1 Ch 5 Bit2
    umbrella(4)  <= hits_i(1);  -- panel= 7 paddle= 65 station=umbrella; LTB DSI1 J1 Ch 3 Bit1
    umbrella(5)  <= hits_i(0);  -- panel= 7 paddle= 66 station=umbrella; LTB DSI1 J1 Ch 1 Bit0
    umbrella(6)  <= hits_i(8);  -- panel= 7 paddle= 67 station=umbrella; LTB DSI1 J2 Ch 2 Bit0
    umbrella(7)  <= hits_i(9);  -- panel= 7 paddle= 68 station=umbrella; LTB DSI1 J2 Ch 4 Bit1
    umbrella(8)  <= hits_i(10);  -- panel= 7 paddle= 69 station=umbrella; LTB DSI1 J2 Ch 6 Bit2
    umbrella(9)  <= hits_i(11);  -- panel= 7 paddle= 70 station=umbrella; LTB DSI1 J2 Ch 8 Bit3
    umbrella(10) <= hits_i(12);  -- panel= 7 paddle= 71 station=umbrella; LTB DSI1 J2 Ch10 Bit4
    umbrella(11) <= hits_i(13);  -- panel= 7 paddle= 72 station=umbrella; LTB DSI1 J2 Ch12 Bit5
    umbrella(12) <= hits_i(6);  -- panel= 8 paddle= 73 station=umbrella; LTB DSI1 J1 Ch13 Bit6
    umbrella(13) <= hits_i(7);  -- panel= 8 paddle= 74 station=umbrella; LTB DSI1 J1 Ch15 Bit7
    umbrella(14) <= hits_i(16);  -- panel= 8 paddle= 75 station=umbrella; LTB DSI1 J3 Ch 1 Bit0
    umbrella(15) <= hits_i(17);  -- panel= 8 paddle= 76 station=umbrella; LTB DSI1 J3 Ch 3 Bit1
    umbrella(16) <= hits_i(18);  -- panel= 8 paddle= 77 station=umbrella; LTB DSI1 J3 Ch 5 Bit2
    umbrella(17) <= hits_i(19);  -- panel= 8 paddle= 78 station=umbrella; LTB DSI1 J3 Ch 7 Bit3
    umbrella(18) <= hits_i(39);  -- panel= 9 paddle= 79 station=umbrella; LTB DSI1 J5 Ch15 Bit7
    umbrella(19) <= hits_i(38);  -- panel= 9 paddle= 80 station=umbrella; LTB DSI1 J5 Ch13 Bit6
    umbrella(20) <= hits_i(37);  -- panel= 9 paddle= 81 station=umbrella; LTB DSI1 J5 Ch11 Bit5
    umbrella(21) <= hits_i(36);  -- panel= 9 paddle= 82 station=umbrella; LTB DSI1 J5 Ch 9 Bit4
    umbrella(22) <= hits_i(35);  -- panel= 9 paddle= 83 station=umbrella; LTB DSI1 J5 Ch 7 Bit3
    umbrella(23) <= hits_i(34);  -- panel= 9 paddle= 84 station=umbrella; LTB DSI1 J5 Ch 5 Bit2
    umbrella(24) <= hits_i(33);  -- panel=10 paddle= 85 station=umbrella; LTB DSI1 J5 Ch 3 Bit1
    umbrella(25) <= hits_i(32);  -- panel=10 paddle= 86 station=umbrella; LTB DSI1 J5 Ch 1 Bit0
    umbrella(26) <= hits_i(31);  -- panel=10 paddle= 87 station=umbrella; LTB DSI1 J4 Ch15 Bit7
    umbrella(27) <= hits_i(30);  -- panel=10 paddle= 88 station=umbrella; LTB DSI1 J4 Ch13 Bit6
    umbrella(28) <= hits_i(29);  -- panel=10 paddle= 89 station=umbrella; LTB DSI1 J4 Ch11 Bit5
    umbrella(29) <= hits_i(28);  -- panel=10 paddle= 90 station=umbrella; LTB DSI1 J4 Ch 9 Bit4
    umbrella(30) <= hits_i(14);  -- panel=11 paddle= 91 station=umbrella; LTB DSI1 J2 Ch14 Bit6
    umbrella(31) <= hits_i(15);  -- panel=11 paddle= 92 station=umbrella; LTB DSI1 J2 Ch16 Bit7
    umbrella(32) <= hits_i(24);  -- panel=11 paddle= 93 station=umbrella; LTB DSI1 J4 Ch 1 Bit0
    umbrella(33) <= hits_i(25);  -- panel=11 paddle= 94 station=umbrella; LTB DSI1 J4 Ch 3 Bit1
    umbrella(34) <= hits_i(26);  -- panel=11 paddle= 95 station=umbrella; LTB DSI1 J4 Ch 5 Bit2
    umbrella(35) <= hits_i(27);  -- panel=11 paddle= 96 station=umbrella; LTB DSI1 J4 Ch 7 Bit3
    umbrella(36) <= hits_i(47);  -- panel=12 paddle= 97 station=umbrella; LTB DSI2 J1 Ch15 Bit7
    umbrella(37) <= hits_i(46);  -- panel=12 paddle= 98 station=umbrella; LTB DSI2 J1 Ch13 Bit6
    umbrella(38) <= hits_i(45);  -- panel=12 paddle= 99 station=umbrella; LTB DSI2 J1 Ch11 Bit5
    umbrella(39) <= hits_i(44);  -- panel=12 paddle=100 station=umbrella; LTB DSI2 J1 Ch 9 Bit4
    umbrella(40) <= hits_i(43);  -- panel=12 paddle=101 station=umbrella; LTB DSI2 J1 Ch 7 Bit3
    umbrella(41) <= hits_i(42);  -- panel=12 paddle=102 station=umbrella; LTB DSI2 J1 Ch 5 Bit2
    umbrella(42) <= hits_i(41);  -- panel=13 paddle=103 station=umbrella; LTB DSI2 J1 Ch 3 Bit1
    umbrella(43) <= hits_i(40);  -- panel=13 paddle=104 station=umbrella; LTB DSI2 J1 Ch 1 Bit0
    umbrella(44) <= hits_i(23);  -- panel=13 paddle=105 station=umbrella; LTB DSI1 J3 Ch15 Bit7
    umbrella(45) <= hits_i(22);  -- panel=13 paddle=106 station=umbrella; LTB DSI1 J3 Ch13 Bit6
    umbrella(46) <= hits_i(21);  -- panel=13 paddle=107 station=umbrella; LTB DSI1 J3 Ch11 Bit5
    umbrella(47) <= hits_i(20);  -- panel=13 paddle=108 station=umbrella; LTB DSI1 J3 Ch 9 Bit4

    cube_bot(0)  <= hits_i(72);  -- panel= 2 paddle= 13 station=cube_bot; LTB DSI2 J5 Ch 2 Bit0
    cube_bot(1)  <= hits_i(73);  -- panel= 2 paddle= 14 station=cube_bot; LTB DSI2 J5 Ch 4 Bit1
    cube_bot(2)  <= hits_i(74);  -- panel= 2 paddle= 15 station=cube_bot; LTB DSI2 J5 Ch 6 Bit2
    cube_bot(3)  <= hits_i(75);  -- panel= 2 paddle= 16 station=cube_bot; LTB DSI2 J5 Ch 8 Bit3
    cube_bot(4)  <= hits_i(76);  -- panel= 2 paddle= 17 station=cube_bot; LTB DSI2 J5 Ch10 Bit4
    cube_bot(5)  <= hits_i(77);  -- panel= 2 paddle= 18 station=cube_bot; LTB DSI2 J5 Ch12 Bit5
    cube_bot(6)  <= hits_i(106);  -- panel= 2 paddle= 19 station=cube_bot; LTB DSI3 J4 Ch 5 Bit2
    cube_bot(7)  <= hits_i(107);  -- panel= 2 paddle= 20 station=cube_bot; LTB DSI3 J4 Ch 7 Bit3
    cube_bot(8)  <= hits_i(108);  -- panel= 2 paddle= 21 station=cube_bot; LTB DSI3 J4 Ch 9 Bit4
    cube_bot(9)  <= hits_i(109);  -- panel= 2 paddle= 22 station=cube_bot; LTB DSI3 J4 Ch11 Bit5
    cube_bot(10) <= hits_i(110);  -- panel= 2 paddle= 23 station=cube_bot; LTB DSI3 J4 Ch13 Bit6
    cube_bot(11) <= hits_i(111);  -- panel= 2 paddle= 24 station=cube_bot; LTB DSI3 J4 Ch15 Bit7

    cube_corner(0) <= hits_i(81);  -- panel=E-X045 paddle= 57 station=cube_corner; LTB DSI3 J1 Ch 4 Bit1
    cube_corner(1) <= hits_i(102);  -- panel=E-X135 paddle= 58 station=cube_corner; LTB DSI3 J3 Ch14 Bit6
    cube_corner(2) <= hits_i(129);  -- panel=E-X225 paddle= 59 station=cube_corner; LTB DSI4 J2 Ch 4 Bit1
    cube_corner(3) <= hits_i(54);  -- panel=E-X315 paddle= 60 station=cube_corner; LTB DSI2 J2 Ch14 Bit6

    cortina(0)  <= hits_i(71);  -- panel=14 paddle=109 station=cortina; LTB DSI2 J4 Ch16 Bit7
    cortina(1)  <= hits_i(70);  -- panel=14 paddle=110 station=cortina; LTB DSI2 J4 Ch14 Bit6
    cortina(2)  <= hits_i(79);  -- panel=14 paddle=111 station=cortina; LTB DSI2 J5 Ch16 Bit7
    cortina(3)  <= hits_i(78);  -- panel=14 paddle=112 station=cortina; LTB DSI2 J5 Ch14 Bit6
    cortina(4)  <= hits_i(84);  -- panel=14 paddle=113 station=cortina; LTB DSI3 J1 Ch10 Bit4
    cortina(5)  <= hits_i(83);  -- panel=14 paddle=114 station=cortina; LTB DSI3 J1 Ch 8 Bit3
    cortina(6)  <= hits_i(82);  -- panel=14 paddle=115 station=cortina; LTB DSI3 J1 Ch 6 Bit2
    cortina(7)  <= hits_i(48);  -- panel=14 paddle=116 station=cortina; LTB DSI2 J2 Ch 2 Bit0
    cortina(8)  <= hits_i(49);  -- panel=14 paddle=117 station=cortina; LTB DSI2 J2 Ch 4 Bit1
    cortina(9)  <= hits_i(50);  -- panel=14 paddle=118 station=cortina; LTB DSI2 J2 Ch 6 Bit2
    cortina(10) <= hits_i(159);  -- panel=15 paddle=119 station=cortina; LTB DSI4 J5 Ch16 Bit7
    cortina(11) <= hits_i(158);  -- panel=15 paddle=120 station=cortina; LTB DSI4 J5 Ch14 Bit6
    cortina(12) <= hits_i(157);  -- panel=15 paddle=121 station=cortina; LTB DSI4 J5 Ch12 Bit5
    cortina(13) <= hits_i(156);  -- panel=15 paddle=122 station=cortina; LTB DSI4 J5 Ch10 Bit4
    cortina(14) <= hits_i(155);  -- panel=15 paddle=123 station=cortina; LTB DSI4 J5 Ch 8 Bit3
    cortina(15) <= hits_i(154);  -- panel=15 paddle=124 station=cortina; LTB DSI4 J5 Ch 6 Bit2
    cortina(16) <= hits_i(153);  -- panel=15 paddle=125 station=cortina; LTB DSI4 J5 Ch 4 Bit1
    cortina(17) <= hits_i(152);  -- panel=15 paddle=126 station=cortina; LTB DSI4 J5 Ch 2 Bit0
    cortina(18) <= hits_i(103);  -- panel=15 paddle=127 station=cortina; LTB DSI3 J3 Ch16 Bit7
    cortina(19) <= hits_i(80);  -- panel=15 paddle=128 station=cortina; LTB DSI3 J1 Ch 2 Bit0
    cortina(20) <= hits_i(112);  -- panel=16 paddle=129 station=cortina; LTB DSI3 J5 Ch 2 Bit0
    cortina(21) <= hits_i(113);  -- panel=16 paddle=130 station=cortina; LTB DSI3 J5 Ch 4 Bit1
    cortina(22) <= hits_i(104);  -- panel=16 paddle=131 station=cortina; LTB DSI3 J4 Ch 2 Bit0
    cortina(23) <= hits_i(105);  -- panel=16 paddle=132 station=cortina; LTB DSI3 J4 Ch 4 Bit1
    cortina(24) <= hits_i(99);  -- panel=16 paddle=133 station=cortina; LTB DSI3 J3 Ch 8 Bit3
    cortina(25) <= hits_i(100);  -- panel=16 paddle=134 station=cortina; LTB DSI3 J3 Ch10 Bit4
    cortina(26) <= hits_i(101);  -- panel=16 paddle=135 station=cortina; LTB DSI3 J3 Ch12 Bit5
    cortina(27) <= hits_i(135);  -- panel=16 paddle=136 station=cortina; LTB DSI4 J2 Ch16 Bit7
    cortina(28) <= hits_i(134);  -- panel=16 paddle=137 station=cortina; LTB DSI4 J2 Ch14 Bit6
    cortina(29) <= hits_i(133);  -- panel=16 paddle=138 station=cortina; LTB DSI4 J2 Ch12 Bit5
    cortina(30) <= hits_i(136);  -- panel=17 paddle=139 station=cortina; LTB DSI4 J3 Ch 2 Bit0
    cortina(31) <= hits_i(137);  -- panel=17 paddle=140 station=cortina; LTB DSI4 J3 Ch 4 Bit1
    cortina(32) <= hits_i(138);  -- panel=17 paddle=141 station=cortina; LTB DSI4 J3 Ch 6 Bit2
    cortina(33) <= hits_i(139);  -- panel=17 paddle=142 station=cortina; LTB DSI4 J3 Ch 8 Bit3
    cortina(34) <= hits_i(140);  -- panel=17 paddle=143 station=cortina; LTB DSI4 J3 Ch10 Bit4
    cortina(35) <= hits_i(141);  -- panel=17 paddle=144 station=cortina; LTB DSI4 J3 Ch12 Bit5
    cortina(36) <= hits_i(142);  -- panel=17 paddle=145 station=cortina; LTB DSI4 J3 Ch14 Bit6
    cortina(37) <= hits_i(143);  -- panel=17 paddle=146 station=cortina; LTB DSI4 J3 Ch16 Bit7
    cortina(38) <= hits_i(128);  -- panel=17 paddle=147 station=cortina; LTB DSI4 J2 Ch 2 Bit0
    cortina(39) <= hits_i(55);  -- panel=17 paddle=148 station=cortina; LTB DSI2 J2 Ch16 Bit7
    cortina(40) <= hits_i(85);  -- panel=18 paddle=149 station=cortina; LTB DSI3 J1 Ch12 Bit5
    cortina(41) <= hits_i(86);  -- panel=18 paddle=150 station=cortina; LTB DSI3 J1 Ch14 Bit6
    cortina(42) <= hits_i(87);  -- panel=18 paddle=151 station=cortina; LTB DSI3 J1 Ch16 Bit7
    cortina(43) <= hits_i(96);  -- panel=19 paddle=152 station=cortina; LTB DSI3 J3 Ch 1 Bit0
    cortina(44) <= hits_i(97);  -- panel=19 paddle=153 station=cortina; LTB DSI3 J3 Ch 3 Bit1
    cortina(45) <= hits_i(98);  -- panel=19 paddle=154 station=cortina; LTB DSI3 J3 Ch 5 Bit2
    cortina(46) <= hits_i(130);  -- panel=20 paddle=155 station=cortina; LTB DSI4 J2 Ch 5 Bit2
    cortina(47) <= hits_i(131);  -- panel=20 paddle=156 station=cortina; LTB DSI4 J2 Ch 7 Bit3
    cortina(48) <= hits_i(132);  -- panel=20 paddle=157 station=cortina; LTB DSI4 J2 Ch 9 Bit4
    cortina(49) <= hits_i(51);  -- panel=21 paddle=158 station=cortina; LTB DSI2 J2 Ch 8 Bit3
    cortina(50) <= hits_i(52);  -- panel=21 paddle=159 station=cortina; LTB DSI2 J2 Ch10 Bit4
    cortina(51) <= hits_i(53);  -- panel=21 paddle=160 station=cortina; LTB DSI2 J2 Ch12 Bit5

    --END: autoinsert mapping

  end process;

  --------------------------------------------------------------------------------
  -- Programmable Trigger
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      programmable_trigger <= or_reduce(hit_bitmap(31 downto 0) and trig_mask_a) and
                              or_reduce(hit_bitmap(31 downto 0) and trig_mask_b);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- SSL triggers
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then

      --START: autoinsert triggers

      ssl_trig_top_bot <=
        ((or_reduce(x"3F" and get_hits_from_slot(hit_bitmap, 2, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hit_bitmap, 3, 2)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hit_bitmap, 2, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hit_bitmap, 2, 4))));

      ssl_trig_topedge_bot <=
        ((or_reduce(x"C0" and get_hits_from_slot(hit_bitmap, 2, 1)) or
          or_reduce(x"30" and get_hits_from_slot(hit_bitmap, 2, 2)) or
          or_reduce(x"3C" and get_hits_from_slot(hit_bitmap, 3, 5)) or
          or_reduce(x"03" and get_hits_from_slot(hit_bitmap, 3, 2)) or
          or_reduce(x"0C" and get_hits_from_slot(hit_bitmap, 3, 1)) or
          or_reduce(x"3C" and get_hits_from_slot(hit_bitmap, 3, 3)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hit_bitmap, 2, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hit_bitmap, 2, 4))));

      ssl_trig_top_botedge <=
        ((or_reduce(x"3F" and get_hits_from_slot(hit_bitmap, 2, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hit_bitmap, 3, 2)))
         and
         (or_reduce(x"0F" and get_hits_from_slot(hit_bitmap, 2, 2)) or
          or_reduce(x"C3" and get_hits_from_slot(hit_bitmap, 3, 5)) or
          or_reduce(x"F0" and get_hits_from_slot(hit_bitmap, 3, 1)) or
          or_reduce(x"C3" and get_hits_from_slot(hit_bitmap, 3, 3))));

      ssl_trig_topmid_botmid <=
        ((or_reduce(x"03" and get_hits_from_slot(hit_bitmap, 2, 1)) or
          or_reduce(x"C0" and get_hits_from_slot(hit_bitmap, 3, 2)))
         and
         (or_reduce(x"30" and get_hits_from_slot(hit_bitmap, 2, 3)) or
          or_reduce(x"0C" and get_hits_from_slot(hit_bitmap, 2, 4))));

      --END: autoinsert triggers

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Source Prescalers
  --------------------------------------------------------------------------------
  --
  -- Ideal situation would be:
  --
  -- - We start a run, in which three triggers are enable: Normal TOF, poisson,
  --   inner+outer
  --
  -- - The triggers run simultaneously and the MTB has to identify and tag which
  --   trigger caused it to fire.
  --
  -- - The normal TOF trigger is not prescaled, we will read do trace
  --   suppression (hopefully in firmware) and the rate will be something like
  --   350-500Hz
  --
  -- - The poisson trigger is set to some low rate, we will read out all RBs and
  --   the rate will be something like 0.1 Hz.
  --
  -- - The inner+outer trigger is prescaled by a factor of 1000 (can be
  --   programmable); we can do trace suppression (or not); this rate should be
  --   around 1-5 Hz or so.
  --
  -- - We keep the "any" trigger in our back pocket with the option of running
  --   it in parallel as well.
  --
  --------------------------------------------------------------------------------

  urand_inf_single_hit : entity work.urand_inf
    generic map (SEED => 0)
    port map (
      clk   => clk,
      rst_n => not reset,
      u     => any_hit_trigger_urand
      );

  urand_inf_track_trig : entity work.urand_inf
    generic map (SEED => 2)
    port map (
      clk   => clk,
      rst_n => not reset,
      u     => track_trigger_urand
      );

  process (clk) is
  begin
    if (rising_edge(clk)) then

      if (any_hit_trigger_prescale /= x"00000000" and
        any_hit_trigger_prescale > any_hit_trigger_urand) then
        any_hit_trigger_en <= '1';
      else
        any_hit_trigger_en <= '0';
      end if;

      if (track_trigger_prescale /= x"00000000" and
          track_trigger_prescale > track_trigger_urand) then
        track_trigger_en <= '1';
      else
        track_trigger_en <= '0';
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Source OR
  --------------------------------------------------------------------------------

  trig_sources <= "0000000"
                  & track_trigger
                  & force_trigger_i
                  & any_trigger
                  & gaps_trigger
                  & (ssl_trig_top_bot_en and ssl_trig_top_bot)
                  & (ssl_trig_topedge_bot_en and ssl_trig_topedge_bot)
                  & (ssl_trig_top_botedge_en and ssl_trig_top_botedge)
                  & (ssl_trig_topmid_botmid_en and ssl_trig_topmid_botmid)
                  & programmable_trigger;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      trig_sources_reg <= trig_sources;

      pedestal_trig <= force_trigger_i or
                       (any_trigger and any_hit_trigger_is_global) or
                       (track_trigger and track_trigger_is_global) or
                       read_all_channels;

      pre_trigger <= not busy_i
                     and not pre_trigger
                     and not dead
                     and or_reduce(trig_sources);
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Map LTB channels onto RB channels to create a bitmap of which RB channels
  -- should be read
  --------------------------------------------------------------------------------

  rb_map_inst : entity work.rb_map
    port map (
      clock          => clk,
      hits_bitmap_i  => hit_bitmap_dly(hit_bitmap_dly'high),
      rb_ch_bitmap_o => rb_ch_bitmap);

  -- the nature of the GAPS trigger is that a track with good timing resolution
  -- defines the trigger. This is the direct digitization of a particle passing
  -- through the TOF, before decay. Because of this, the hits should happen
  -- close together. This means that the trigger does not need to look in a very
  -- wide time window.
  --
  -- When determining the channels in the RB that need to be read, however, the
  -- MTB needs to consider a longer time window /after/ the trigger decision is
  -- made to account for decay time, slow moving particles, etc.
  --
  -- the integrator module opens a time window after a trigger and accumulates hits
  -- for a programmable number of clock cycles, after which a trigger + hit mask
  -- are sent to the readout boards

  integrator_inst : entity work.integrator
    generic map (
      MAX   => 31,
      WIDTH => rb_ch_bitmap'length
      )
    port map (
      clk    => clk,
      trg_i  => pre_trigger,
      trg_o  => rb_trigger,
      d      => rb_ch_bitmap, -- align to pretrigger
      q      => rb_ch_integrated,
      window => to_integer(unsigned(rb_window_i))
      );

  process (clk) is
  begin
    if (rising_edge(clk)) then
      rb_trigger_o <= rb_trigger;
      if (rb_trigger = '1') then
        if (pedestal_trig_latch = '1') then
          rb_ch_bitmap_o <= (others => '1');
        else
          rb_ch_bitmap_o <= rb_ch_integrated;
        end if;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Outputs and Delaylines
  --------------------------------------------------------------------------------

  pre_trigger_o <= pre_trigger;



  process (clk) is
  begin
    if (rising_edge(clk)) then

      -- this should be delayed to align with the trigger
      hits_dly(0) <= hits_i;
      hits_o      <= hits_dly(hits_dly'length-1);
      for I in 1 to hits_dly'length-1 loop
        hits_dly(I) <= hits_dly(I-1);
      end loop;

      hit_bitmap_dly(0) <= hit_bitmap;
      for I in 1 to hit_bitmap_dly'length-1 loop
        hit_bitmap_dly(I) <= hit_bitmap_dly(I-1);
      end loop;

      lost_trigger_o   <= busy_i and pre_trigger;
      global_trigger_o <= pre_trigger;  -- delay by 1 clock to align with event count

      if (pre_trigger) then
        trig_sources_o      <= trig_sources_reg;
        pedestal_trig_latch <= pedestal_trig;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Counter
  --------------------------------------------------------------------------------

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset or event_cnt_reset,
      global_trigger_i => pre_trigger,
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
      if (dead = '0' and pre_trigger = '1') then
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
