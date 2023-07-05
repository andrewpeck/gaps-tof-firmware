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

    single_hit_en_i : in std_logic := '0';

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

    pre_trigger_o    : out std_logic;
    global_trigger_o : out std_logic;
    lost_trigger_o   : out std_logic;
    rb_trigger_o     : out std_logic;
    rb_ch_bitmap_o   : out std_logic_vector (NUM_RBS*8-1 downto 0);
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
  constant TRIG_LATENCY : integer := 3;
  type hits_dlyline_t is array (integer range <>) of threshold_array_t;
  signal hits_dly       : hits_dlyline_t (TRIG_LATENCY-1 downto 0);

  constant HIT_BITMAP_LATENCY : integer := TRIG_LATENCY-1;
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
  constant N_CORTINA     : integer := 9;
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

  signal cube_cnts        : integer range 0 to N_CUBE;
  signal cube_bot_cnts    : integer range 0 to N_CUBE_BOT;
  signal cube_corner_cnts : integer range 0 to N_CUBE_CORNER;
  signal umbrella_cnts    : integer range 0 to N_UMBRELLA;
  signal cortina_cnts     : integer range 0 to N_CORTINA;
  signal inner_tof_cnts   : integer range 0 to N_INNER_TOF;
  signal outer_tof_cnts   : integer range 0 to N_OUTER_TOF;
  signal total_tof_cnts   : integer range 0 to N_OUTER_TOF;

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

  signal per_channel_triggers : channel_bitmask_t := (others => '0');

  constant NUM_CHANNELS : integer := per_channel_triggers'length;

  signal rb_triggers      : std_logic_vector (NUM_RBS-1 downto 0);
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

  single_hit_trg_gen : for I in 0 to hits_i'length-1 generate
  begin
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (unsigned(hits_i(I)) > unsigned(hit_thresh)) then
          hitmask(I) <= '1';
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

  gaps_trigger <= (not require_beta or or_inner_tof_beta) and
                  (not require_beta or or_outer_tof_beta) and
                  inner_tof_over_thresh and
                  outer_tof_over_thresh and
                  total_tof_over_thresh;

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

    cube(0)  <= hits_i(0);              -- panel=1 paddle=1 station=cube
    cube(1)  <= hits_i(1);              -- panel=1 paddle=2 station=cube
    cube(2)  <= hits_i(2);              -- panel=1 paddle=3 station=cube
    cube(3)  <= hits_i(3);              -- panel=1 paddle=4 station=cube
    cube(4)  <= hits_i(4);              -- panel=1 paddle=5 station=cube
    cube(5)  <= hits_i(5);              -- panel=1 paddle=6 station=cube
    cube(6)  <= hits_i(6);              -- panel=1 paddle=7 station=cube
    cube(7)  <= hits_i(7);              -- panel=1 paddle=8 station=cube
    cube(8)  <= hits_i(8);              -- panel=1 paddle=9 station=cube
    cube(9)  <= hits_i(9);              -- panel=1 paddle=10 station=cube
    cube(10) <= hits_i(10);             -- panel=1 paddle=11 station=cube
    cube(11) <= hits_i(11);             -- panel=1 paddle=12 station=cube
    cube(12) <= hits_i(24);             -- panel=3 paddle=25 station=cube
    cube(13) <= hits_i(25);             -- panel=3 paddle=26 station=cube
    cube(14) <= hits_i(26);             -- panel=3 paddle=27 station=cube
    cube(15) <= hits_i(27);             -- panel=3 paddle=28 station=cube
    cube(16) <= hits_i(28);             -- panel=3 paddle=29 station=cube
    cube(17) <= hits_i(29);             -- panel=3 paddle=30 station=cube
    cube(18) <= hits_i(30);             -- panel=3 paddle=31 station=cube
    cube(19) <= hits_i(31);             -- panel=3 paddle=32 station=cube
    cube(20) <= hits_i(32);             -- panel=4 paddle=33 station=cube
    cube(21) <= hits_i(33);             -- panel=4 paddle=34 station=cube
    cube(22) <= hits_i(34);             -- panel=4 paddle=35 station=cube
    cube(23) <= hits_i(35);             -- panel=4 paddle=36 station=cube
    cube(24) <= hits_i(36);             -- panel=4 paddle=37 station=cube
    cube(25) <= hits_i(37);             -- panel=4 paddle=38 station=cube
    cube(26) <= hits_i(38);             -- panel=4 paddle=39 station=cube
    cube(27) <= hits_i(39);             -- panel=4 paddle=40 station=cube
    cube(28) <= hits_i(40);             -- panel=5 paddle=41 station=cube
    cube(29) <= hits_i(41);             -- panel=5 paddle=42 station=cube
    cube(30) <= hits_i(42);             -- panel=5 paddle=43 station=cube
    cube(31) <= hits_i(43);             -- panel=5 paddle=44 station=cube
    cube(32) <= hits_i(44);             -- panel=5 paddle=45 station=cube
    cube(33) <= hits_i(45);             -- panel=5 paddle=46 station=cube
    cube(34) <= hits_i(46);             -- panel=5 paddle=47 station=cube
    cube(35) <= hits_i(47);             -- panel=5 paddle=48 station=cube
    cube(36) <= hits_i(48);             -- panel=6 paddle=49 station=cube
    cube(37) <= hits_i(49);             -- panel=6 paddle=50 station=cube
    cube(38) <= hits_i(50);             -- panel=6 paddle=51 station=cube
    cube(39) <= hits_i(51);             -- panel=6 paddle=52 station=cube
    cube(40) <= hits_i(52);             -- panel=6 paddle=53 station=cube
    cube(41) <= hits_i(53);             -- panel=6 paddle=54 station=cube
    cube(42) <= hits_i(54);             -- panel=6 paddle=55 station=cube
    cube(43) <= hits_i(55);             -- panel=6 paddle=56 station=cube

    umbrella(0)  <= hits_i(60);         -- panel=7 paddle=61 station=umbrella
    umbrella(1)  <= hits_i(61);         -- panel=7 paddle=62 station=umbrella
    umbrella(2)  <= hits_i(62);         -- panel=7 paddle=63 station=umbrella
    umbrella(3)  <= hits_i(63);         -- panel=7 paddle=64 station=umbrella
    umbrella(4)  <= hits_i(64);         -- panel=7 paddle=65 station=umbrella
    umbrella(5)  <= hits_i(65);         -- panel=7 paddle=66 station=umbrella
    umbrella(6)  <= hits_i(66);         -- panel=7 paddle=67 station=umbrella
    umbrella(7)  <= hits_i(67);         -- panel=7 paddle=68 station=umbrella
    umbrella(8)  <= hits_i(68);         -- panel=7 paddle=69 station=umbrella
    umbrella(9)  <= hits_i(69);         -- panel=7 paddle=70 station=umbrella
    umbrella(10) <= hits_i(70);         -- panel=7 paddle=71 station=umbrella
    umbrella(11) <= hits_i(71);         -- panel=7 paddle=72 station=umbrella
    umbrella(12) <= hits_i(72);         -- panel=8 paddle=73 station=umbrella
    umbrella(13) <= hits_i(73);         -- panel=8 paddle=74 station=umbrella
    umbrella(14) <= hits_i(74);         -- panel=8 paddle=75 station=umbrella
    umbrella(15) <= hits_i(75);         -- panel=8 paddle=76 station=umbrella
    umbrella(16) <= hits_i(76);         -- panel=8 paddle=77 station=umbrella
    umbrella(17) <= hits_i(77);         -- panel=8 paddle=78 station=umbrella
    umbrella(18) <= hits_i(78);         -- panel=9 paddle=79 station=umbrella
    umbrella(19) <= hits_i(79);         -- panel=9 paddle=80 station=umbrella
    umbrella(20) <= hits_i(80);         -- panel=9 paddle=81 station=umbrella
    umbrella(21) <= hits_i(81);         -- panel=9 paddle=82 station=umbrella
    umbrella(22) <= hits_i(82);         -- panel=9 paddle=83 station=umbrella
    umbrella(23) <= hits_i(83);         -- panel=9 paddle=84 station=umbrella
    umbrella(24) <= hits_i(84);         -- panel=10 paddle=85 station=umbrella
    umbrella(25) <= hits_i(85);         -- panel=10 paddle=86 station=umbrella
    umbrella(26) <= hits_i(86);         -- panel=10 paddle=87 station=umbrella
    umbrella(27) <= hits_i(87);         -- panel=10 paddle=88 station=umbrella
    umbrella(28) <= hits_i(88);         -- panel=10 paddle=89 station=umbrella
    umbrella(29) <= hits_i(89);         -- panel=10 paddle=90 station=umbrella
    umbrella(30) <= hits_i(90);         -- panel=11 paddle=91 station=umbrella
    umbrella(31) <= hits_i(91);         -- panel=11 paddle=92 station=umbrella
    umbrella(32) <= hits_i(92);         -- panel=11 paddle=93 station=umbrella
    umbrella(33) <= hits_i(93);         -- panel=11 paddle=94 station=umbrella
    umbrella(34) <= hits_i(94);         -- panel=11 paddle=95 station=umbrella
    umbrella(35) <= hits_i(95);         -- panel=11 paddle=96 station=umbrella
    umbrella(36) <= hits_i(96);         -- panel=12 paddle=97 station=umbrella
    umbrella(37) <= hits_i(97);         -- panel=12 paddle=98 station=umbrella
    umbrella(38) <= hits_i(98);         -- panel=12 paddle=99 station=umbrella
    umbrella(39) <= hits_i(99);         -- panel=12 paddle=100 station=umbrella
    umbrella(40) <= hits_i(100);        -- panel=12 paddle=101 station=umbrella
    umbrella(41) <= hits_i(101);        -- panel=12 paddle=102 station=umbrella
    umbrella(42) <= hits_i(102);        -- panel=13 paddle=103 station=umbrella
    umbrella(43) <= hits_i(103);        -- panel=13 paddle=104 station=umbrella
    umbrella(44) <= hits_i(104);        -- panel=13 paddle=105 station=umbrella
    umbrella(45) <= hits_i(105);        -- panel=13 paddle=106 station=umbrella
    umbrella(46) <= hits_i(106);        -- panel=13 paddle=107 station=umbrella
    umbrella(47) <= hits_i(107);        -- panel=13 paddle=108 station=umbrella

    cube_bot(0)  <= hits_i(12);         -- panel=2 paddle=13 station=cube_bot
    cube_bot(1)  <= hits_i(13);         -- panel=2 paddle=14 station=cube_bot
    cube_bot(2)  <= hits_i(14);         -- panel=2 paddle=15 station=cube_bot
    cube_bot(3)  <= hits_i(15);         -- panel=2 paddle=16 station=cube_bot
    cube_bot(4)  <= hits_i(16);         -- panel=2 paddle=17 station=cube_bot
    cube_bot(5)  <= hits_i(17);         -- panel=2 paddle=18 station=cube_bot
    cube_bot(6)  <= hits_i(18);         -- panel=2 paddle=19 station=cube_bot
    cube_bot(7)  <= hits_i(19);         -- panel=2 paddle=20 station=cube_bot
    cube_bot(8)  <= hits_i(20);         -- panel=2 paddle=21 station=cube_bot
    cube_bot(9)  <= hits_i(21);         -- panel=2 paddle=22 station=cube_bot
    cube_bot(10) <= hits_i(22);         -- panel=2 paddle=23 station=cube_bot
    cube_bot(11) <= hits_i(23);         -- panel=2 paddle=24 station=cube_bot

    cube_corner(0) <= hits_i(56);  -- panel=:N/A paddle=57 station=cube_corner
    cube_corner(1) <= hits_i(57);  -- panel=:N/A paddle=58 station=cube_corner
    cube_corner(2) <= hits_i(58);  -- panel=:N/A paddle=59 station=cube_corner
    cube_corner(3) <= hits_i(59);  -- panel=:N/A paddle=60 station=cube_corner


    --END: autoinsert mapping

    cortina(0) <= hits_i(108);
    cortina(1) <= hits_i(109);
    cortina(2) <= hits_i(110);
    cortina(3) <= hits_i(111);
    cortina(4) <= hits_i(112);
    cortina(5) <= hits_i(113);
    cortina(6) <= hits_i(114);
    cortina(7) <= hits_i(115);
    cortina(8) <= hits_i(116);

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
        ((or_reduce(x"3F" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 3, 2)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hitmask, 2, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 2, 4))));

      ssl_trig_topedge_bot <=
        ((or_reduce(x"C0" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"30" and get_hits_from_slot(hitmask, 2, 2)) or
          or_reduce(x"3C" and get_hits_from_slot(hitmask, 3, 5)) or
          or_reduce(x"03" and get_hits_from_slot(hitmask, 3, 2)) or
          or_reduce(x"0C" and get_hits_from_slot(hitmask, 3, 1)) or
          or_reduce(x"3C" and get_hits_from_slot(hitmask, 3, 3)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hitmask, 2, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 2, 4))));

      ssl_trig_top_botedge <=
        ((or_reduce(x"3F" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 3, 2)))
         and
         (or_reduce(x"0F" and get_hits_from_slot(hitmask, 2, 2)) or
          or_reduce(x"C3" and get_hits_from_slot(hitmask, 3, 5)) or
          or_reduce(x"F0" and get_hits_from_slot(hitmask, 3, 1)) or
          or_reduce(x"C3" and get_hits_from_slot(hitmask, 3, 3))));

      ssl_trig_topmid_botmid <=
        ((or_reduce(x"03" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"C0" and get_hits_from_slot(hitmask, 3, 2)))
         and
         (or_reduce(x"30" and get_hits_from_slot(hitmask, 2, 3)) or
          or_reduce(x"0C" and get_hits_from_slot(hitmask, 2, 4))));

      --END: autoinsert triggers

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger Source OR
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      pre_trigger <= not busy_i
                     and not dead
                     and (force_trigger_i
                          or (or_reduce(hit_bitmap) and single_hit_en_i)
                          or (gaps_trigger_en and gaps_trigger)
                          or (ssl_trig_top_bot_en and ssl_trig_top_bot)
                          or (ssl_trig_topedge_bot_en and ssl_trig_topedge_bot)
                          or (ssl_trig_top_botedge_en and ssl_trig_top_botedge)
                          or (ssl_trig_topmid_botmid_en and ssl_trig_topmid_botmid)
                          or programmable_trigger);
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
  -- the integrator module opens a time window after a hit and accumulates hits
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
      trg_o  => rb_trigger_o,
      d      => rb_ch_bitmap,
      q      => rb_ch_integrated,
      window => to_integer(unsigned(rb_window_i))
      );

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (pre_trigger = '1') then
        if (read_all_channels = '1') then
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

  hits_o      <= hits_dly(hits_dly'high);
  hits_dly(0) <= hits_i;

  hit_bitmap_dly(0) <= hit_bitmap;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      -- this should be delayed to align with the trigger
      for I in 1 to hits_dly'length-1 loop
        hits_dly(I) <= hits_dly(I-1) after 0.5 ns;
      end loop;

      for I in 1 to hit_bitmap_dly'length-1 loop
        hit_bitmap_dly(I) <= hit_bitmap_dly(I-1) after 0.5 ns;
      end loop;

      lost_trigger_o   <= busy_i and pre_trigger;
      global_trigger_o <= pre_trigger;  -- delay by 1 clock to align with event count

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
