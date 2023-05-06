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

    trig_mask_a : in std_logic_vector (31 downto 0);

    trig_mask_b : in std_logic_vector (31 downto 0);

    all_triggers_are_global : in std_logic := '1';

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

    busy_i    : in std_logic;
    rb_busy_i : in std_logic_vector(NUM_RBS-1 downto 0);

    force_trigger_i : in std_logic;

    pre_trigger_o    : out std_logic;
    channel_select_o : out channel_bitmask_t;
    global_trigger_o : out std_logic;
    lost_trigger_o   : out std_logic;
    rb_triggers_o    : out std_logic_vector (NUM_RBS-1 downto 0);
    event_cnt_o      : out std_logic_vector (31 downto 0)

    );
end trigger;

architecture behavioral of trigger is

  -- t0: + hits_i arrives
  --     + gets async remapped to different stations
  -- t1: + clock onto hit/beta/veto
  -- t2: + count of hits
  --     + inner/outer_tof_thresh
  --     + or_reduce of beta
  -- t3: + gaps trigger -> per_channel_triggers -> global_trigger
  -- t4: + global_trigger_o

  constant TRIG_LATENCY : integer := 4;
  type hits_dlyline_t is array (integer range <>) of threshold_array_t;
  signal hits_dly       : hits_dlyline_t (TRIG_LATENCY-2 downto 0);

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

  constant N_UMBRELLA    : integer := 48;
  constant N_CUBE_BOT    : integer := 12;
  constant N_CUBE        : integer := 44;
  constant N_CORTINA     : integer := 9;
  constant N_CUBE_CORNER : integer := 4;

  constant N_OUTER_TOF : integer := N_UMBRELLA + N_CORTINA;
  constant N_INNER_TOF : integer := N_CUBE_CORNER + N_CUBE + N_CUBE_BOT;

  type cortina_t is
    array(N_CORTINA-1 downto 0) of std_logic_vector(1 downto 0);
  type umbrella_t is
    array(N_UMBRELLA-1 downto 0) of std_logic_vector(1 downto 0);
  type cube_t is
    array(N_CUBE-1 downto 0) of std_logic_vector(1 downto 0);
  type cube_bot_t is
    array(N_CUBE_BOT-1 downto 0) of std_logic_vector(1 downto 0);
  type cube_corner_t is
    array(N_CUBE_CORNER-1 downto 0) of std_logic_vector(1 downto 0);

  signal cube        : cube_t;
  signal cube_bot    : cube_bot_t;
  signal cube_corner : cube_corner_t;
  signal umbrella    : umbrella_t;
  signal cortina     : cortina_t;

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

  --------------------------------------------------------------------------------
  -- Global trigger
  --------------------------------------------------------------------------------

  signal global_trigger : std_logic := '0';

  -- flatten the 200 inputs from a threshold to just a bitmask meaning that a
  -- channel is either on or off
  signal hitmask : channel_bitmask_t := (others => '0');

  signal per_channel_triggers : channel_bitmask_t := (others => '0');

  constant NUM_CHANNELS : integer := per_channel_triggers'length;

  signal rb_triggers, rb_triggers_r : std_logic_vector (NUM_RBS-1 downto 0);

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

  debug_gen : if (DEBUG) generate
    ila_trigger_inst : ila_trigger
      port map (
        clk                => clk,
        probe0(0)          => global_trigger,
        probe0(1)          => global_trigger_o,
        probe0(7 downto 2) => (others => '0'),
        probe1(7 downto 0) => (others => '0'),
        probe2             => busy_i & global_trigger & dead & programmable_trigger,
        probe3             => event_cnt_o,
        probe4             => hitmask
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

      cube_hit  <= (others => '0');
      cube_beta <= (others => '0');

      for I in cube'range loop
        if (cube(I) = "10") then
          cube_beta(I) <= '1';
        end if;
        if (cube(I) /= "00") then
          cube_hit(I) <= '1';
        end if;
      end loop;

      cube_bot_hit  <= (others => '0');
      cube_bot_beta <= (others => '0');

      for I in cube_bot'range loop
        if (cube_bot(I) = "10") then
          cube_bot_beta(I) <= '1';
        end if;
        if (cube_bot(I) /= "00") then
          cube_bot_hit(I) <= '1';
        end if;
      end loop;

      cube_corner_hit  <= (others => '0');
      cube_corner_beta <= (others => '0');

      for I in cube_corner'range loop
        if (cube_corner(I) = "10") then
          cube_corner_beta(I) <= '1';
        end if;
        if (cube_corner(I) /= "00") then
          cube_corner_hit(I) <= '1';
        end if;
      end loop;

      umbrella_hit  <= (others => '0');
      umbrella_beta <= (others => '0');

      for I in umbrella'range loop
        if (umbrella(I) = "10") then
          umbrella_beta(I) <= '1';
        end if;
        if (umbrella(I) /= "00") then
          umbrella_hit(I) <= '1';
        end if;
      end loop;

      cortina_hit  <= (others => '0');
      cortina_beta <= (others => '0');

      for I in cortina'range loop
        if (cortina(I) = "10") then
          cortina_beta(I) <= '1';
        end if;
        if (cortina(I) /= "00") then
          cortina_hit(I) <= '1';
        end if;
      end loop;

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

    cube(0)  <= hits_i(0);              -- panel=1 paddle=1 station=cube (0)
    cube(1)  <= hits_i(1);              -- panel=1 paddle=2 station=cube (1)
    cube(2)  <= hits_i(2);              -- panel=1 paddle=3 station=cube (2)
    cube(3)  <= hits_i(3);              -- panel=1 paddle=4 station=cube (3)
    cube(4)  <= hits_i(4);              -- panel=1 paddle=5 station=cube (4)
    cube(5)  <= hits_i(5);              -- panel=1 paddle=6 station=cube (5)
    cube(6)  <= hits_i(6);              -- panel=1 paddle=7 station=cube (6)
    cube(7)  <= hits_i(7);              -- panel=1 paddle=8 station=cube (7)
    cube(8)  <= hits_i(8);              -- panel=1 paddle=9 station=cube (8)
    cube(9)  <= hits_i(9);              -- panel=1 paddle=10 station=cube (9)
    cube(10) <= hits_i(10);             -- panel=1 paddle=11 station=cube (10)
    cube(11) <= hits_i(11);             -- panel=1 paddle=12 station=cube (11)
    cube(12) <= hits_i(24);             -- panel=3 paddle=25 station=cube (12)
    cube(13) <= hits_i(25);             -- panel=3 paddle=26 station=cube (13)
    cube(14) <= hits_i(26);             -- panel=3 paddle=27 station=cube (14)
    cube(15) <= hits_i(27);             -- panel=3 paddle=28 station=cube (15)
    cube(16) <= hits_i(28);             -- panel=3 paddle=29 station=cube (16)
    cube(17) <= hits_i(29);             -- panel=3 paddle=30 station=cube (17)
    cube(18) <= hits_i(30);             -- panel=3 paddle=31 station=cube (18)
    cube(19) <= hits_i(31);             -- panel=3 paddle=32 station=cube (19)
    cube(20) <= hits_i(32);             -- panel=4 paddle=33 station=cube (20)
    cube(21) <= hits_i(33);             -- panel=4 paddle=34 station=cube (21)
    cube(22) <= hits_i(34);             -- panel=4 paddle=35 station=cube (22)
    cube(23) <= hits_i(35);             -- panel=4 paddle=36 station=cube (23)
    cube(24) <= hits_i(36);             -- panel=4 paddle=37 station=cube (24)
    cube(25) <= hits_i(37);             -- panel=4 paddle=38 station=cube (25)
    cube(26) <= hits_i(38);             -- panel=4 paddle=39 station=cube (26)
    cube(27) <= hits_i(39);             -- panel=4 paddle=40 station=cube (27)
    cube(28) <= hits_i(40);             -- panel=5 paddle=41 station=cube (28)
    cube(29) <= hits_i(41);             -- panel=5 paddle=42 station=cube (29)
    cube(30) <= hits_i(42);             -- panel=5 paddle=43 station=cube (30)
    cube(31) <= hits_i(43);             -- panel=5 paddle=44 station=cube (31)
    cube(32) <= hits_i(44);             -- panel=5 paddle=45 station=cube (32)
    cube(33) <= hits_i(45);             -- panel=5 paddle=46 station=cube (33)
    cube(34) <= hits_i(46);             -- panel=5 paddle=47 station=cube (34)
    cube(35) <= hits_i(47);             -- panel=5 paddle=48 station=cube (35)
    cube(36) <= hits_i(48);             -- panel=6 paddle=49 station=cube (36)
    cube(37) <= hits_i(49);             -- panel=6 paddle=50 station=cube (37)
    cube(38) <= hits_i(50);             -- panel=6 paddle=51 station=cube (38)
    cube(39) <= hits_i(51);             -- panel=6 paddle=52 station=cube (39)
    cube(40) <= hits_i(52);             -- panel=6 paddle=53 station=cube (40)
    cube(41) <= hits_i(53);             -- panel=6 paddle=54 station=cube (41)
    cube(42) <= hits_i(54);             -- panel=6 paddle=55 station=cube (42)
    cube(43) <= hits_i(55);             -- panel=6 paddle=56 station=cube (43)

    umbrella(0)  <= hits_i(60);   -- panel=7 paddle=61 station=umbrella (0)
    umbrella(1)  <= hits_i(61);   -- panel=7 paddle=62 station=umbrella (1)
    umbrella(2)  <= hits_i(62);   -- panel=7 paddle=63 station=umbrella (2)
    umbrella(3)  <= hits_i(63);   -- panel=7 paddle=64 station=umbrella (3)
    umbrella(4)  <= hits_i(64);   -- panel=7 paddle=65 station=umbrella (4)
    umbrella(5)  <= hits_i(65);   -- panel=7 paddle=66 station=umbrella (5)
    umbrella(6)  <= hits_i(66);   -- panel=7 paddle=67 station=umbrella (6)
    umbrella(7)  <= hits_i(67);   -- panel=7 paddle=68 station=umbrella (7)
    umbrella(8)  <= hits_i(68);   -- panel=7 paddle=69 station=umbrella (8)
    umbrella(9)  <= hits_i(69);   -- panel=7 paddle=70 station=umbrella (9)
    umbrella(10) <= hits_i(70);   -- panel=7 paddle=71 station=umbrella (10)
    umbrella(11) <= hits_i(71);   -- panel=7 paddle=72 station=umbrella (11)
    umbrella(12) <= hits_i(72);   -- panel=8 paddle=73 station=umbrella (12)
    umbrella(13) <= hits_i(73);   -- panel=8 paddle=74 station=umbrella (13)
    umbrella(14) <= hits_i(74);   -- panel=8 paddle=75 station=umbrella (14)
    umbrella(15) <= hits_i(75);   -- panel=8 paddle=76 station=umbrella (15)
    umbrella(16) <= hits_i(76);   -- panel=8 paddle=77 station=umbrella (16)
    umbrella(17) <= hits_i(77);   -- panel=8 paddle=78 station=umbrella (17)
    umbrella(18) <= hits_i(78);   -- panel=9 paddle=79 station=umbrella (18)
    umbrella(19) <= hits_i(79);   -- panel=9 paddle=80 station=umbrella (19)
    umbrella(20) <= hits_i(80);   -- panel=9 paddle=81 station=umbrella (20)
    umbrella(21) <= hits_i(81);   -- panel=9 paddle=82 station=umbrella (21)
    umbrella(22) <= hits_i(82);   -- panel=9 paddle=83 station=umbrella (22)
    umbrella(23) <= hits_i(83);   -- panel=9 paddle=84 station=umbrella (23)
    umbrella(24) <= hits_i(84);   -- panel=10 paddle=85 station=umbrella (24)
    umbrella(25) <= hits_i(85);   -- panel=10 paddle=86 station=umbrella (25)
    umbrella(26) <= hits_i(86);   -- panel=10 paddle=87 station=umbrella (26)
    umbrella(27) <= hits_i(87);   -- panel=10 paddle=88 station=umbrella (27)
    umbrella(28) <= hits_i(88);   -- panel=10 paddle=89 station=umbrella (28)
    umbrella(29) <= hits_i(89);   -- panel=10 paddle=90 station=umbrella (29)
    umbrella(30) <= hits_i(90);   -- panel=11 paddle=91 station=umbrella (30)
    umbrella(31) <= hits_i(91);   -- panel=11 paddle=92 station=umbrella (31)
    umbrella(32) <= hits_i(92);   -- panel=11 paddle=93 station=umbrella (32)
    umbrella(33) <= hits_i(93);   -- panel=11 paddle=94 station=umbrella (33)
    umbrella(34) <= hits_i(94);   -- panel=11 paddle=95 station=umbrella (34)
    umbrella(35) <= hits_i(95);   -- panel=11 paddle=96 station=umbrella (35)
    umbrella(36) <= hits_i(96);   -- panel=12 paddle=97 station=umbrella (36)
    umbrella(37) <= hits_i(97);   -- panel=12 paddle=98 station=umbrella (37)
    umbrella(38) <= hits_i(98);   -- panel=12 paddle=99 station=umbrella (38)
    umbrella(39) <= hits_i(99);   -- panel=12 paddle=100 station=umbrella (39)
    umbrella(40) <= hits_i(100);  -- panel=12 paddle=101 station=umbrella (40)
    umbrella(41) <= hits_i(101);  -- panel=12 paddle=102 station=umbrella (41)
    umbrella(42) <= hits_i(102);  -- panel=13 paddle=103 station=umbrella (42)
    umbrella(43) <= hits_i(103);  -- panel=13 paddle=104 station=umbrella (43)
    umbrella(44) <= hits_i(104);  -- panel=13 paddle=105 station=umbrella (44)
    umbrella(45) <= hits_i(105);  -- panel=13 paddle=106 station=umbrella (45)
    umbrella(46) <= hits_i(106);  -- panel=13 paddle=107 station=umbrella (46)
    umbrella(47) <= hits_i(107);  -- panel=13 paddle=108 station=umbrella (47)

    cube_bot(0)  <= hits_i(12);  -- panel=2 paddle=13 station=cube_bot (0)
    cube_bot(1)  <= hits_i(13);  -- panel=2 paddle=14 station=cube_bot (1)
    cube_bot(2)  <= hits_i(14);  -- panel=2 paddle=15 station=cube_bot (2)
    cube_bot(3)  <= hits_i(15);  -- panel=2 paddle=16 station=cube_bot (3)
    cube_bot(4)  <= hits_i(16);  -- panel=2 paddle=17 station=cube_bot (4)
    cube_bot(5)  <= hits_i(17);  -- panel=2 paddle=18 station=cube_bot (5)
    cube_bot(6)  <= hits_i(18);  -- panel=2 paddle=19 station=cube_bot (6)
    cube_bot(7)  <= hits_i(19);  -- panel=2 paddle=20 station=cube_bot (7)
    cube_bot(8)  <= hits_i(20);  -- panel=2 paddle=21 station=cube_bot (8)
    cube_bot(9)  <= hits_i(21);  -- panel=2 paddle=22 station=cube_bot (9)
    cube_bot(10) <= hits_i(22);  -- panel=2 paddle=23 station=cube_bot (10)
    cube_bot(11) <= hits_i(23);  -- panel=2 paddle=24 station=cube_bot (11)

    cube_corner(0) <= hits_i(56);  -- panel=0 paddle=57 station=cube_corner (0)
    cube_corner(1) <= hits_i(57);  -- panel=0 paddle=58 station=cube_corner (1)
    cube_corner(2) <= hits_i(58);  -- panel=0 paddle=59 station=cube_corner (2)
    cube_corner(3) <= hits_i(59);  -- panel=0 paddle=60 station=cube_corner (3)

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
      programmable_trigger <= or_reduce(hitmask(31 downto 0) and trig_mask_a) and
                              or_reduce(hitmask(31 downto 0) and trig_mask_b);
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
        ((or_reduce(x"3F" and get_hits_from_slot(hitmask, 1, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 2, 2)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hitmask, 1, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 1, 4))));

      ssl_trig_topedge_bot <=
        ((or_reduce(x"C0" and get_hits_from_slot(hitmask, 1, 1)) or
          or_reduce(x"30" and get_hits_from_slot(hitmask, 1, 2)) or
          or_reduce(x"3C" and get_hits_from_slot(hitmask, 2, 5)) or
          or_reduce(x"03" and get_hits_from_slot(hitmask, 2, 2)) or
          or_reduce(x"0C" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"3C" and get_hits_from_slot(hitmask, 2, 3)))
         and
         (or_reduce(x"3F" and get_hits_from_slot(hitmask, 1, 3)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 1, 4))));

      ssl_trig_top_botedge <=
        ((or_reduce(x"3F" and get_hits_from_slot(hitmask, 1, 1)) or
          or_reduce(x"FC" and get_hits_from_slot(hitmask, 2, 2)))
         and
         (or_reduce(x"0F" and get_hits_from_slot(hitmask, 1, 2)) or
          or_reduce(x"C3" and get_hits_from_slot(hitmask, 2, 5)) or
          or_reduce(x"F0" and get_hits_from_slot(hitmask, 2, 1)) or
          or_reduce(x"C3" and get_hits_from_slot(hitmask, 2, 3))));

      ssl_trig_topmid_botmid <=
        ((or_reduce(x"03" and get_hits_from_slot(hitmask, 1, 1)) or
          or_reduce(x"C0" and get_hits_from_slot(hitmask, 2, 2)))
         and
         (or_reduce(x"30" and get_hits_from_slot(hitmask, 1, 3)) or
          or_reduce(x"0C" and get_hits_from_slot(hitmask, 1, 4))));

      --END: autoinsert triggers

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
                                                 (gaps_trigger_en and gaps_trigger) or
                                                 (ssl_trig_top_bot_en and ssl_trig_top_bot) or
                                                 (ssl_trig_topedge_bot_en and ssl_trig_topedge_bot) or
                                                 (ssl_trig_top_botedge_en and ssl_trig_top_botedge) or
                                                 (ssl_trig_topmid_botmid_en and ssl_trig_topmid_botmid) or
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

  global_trigger <= not busy_i and not dead and or_reduce(per_channel_triggers);

  --------------------------------------------------------------------------------
  -- outputs
  --------------------------------------------------------------------------------

  pre_trigger_o <= global_trigger;

  hits_o      <= hits_dly(hits_dly'length-1);
  hits_dly(0) <= hits_i;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      -- this should be delayed to align with the trigger
      for I in 1 to hits_dly'length-1 loop
        hits_dly(I) <= hits_dly(I-1);
      end loop;

      lost_trigger_o   <= busy_i and global_trigger;
      rb_triggers_r    <= rb_triggers;
      channel_select_o <= per_channel_triggers;
      rb_triggers_o    <= repeat (not busy_i, rb_triggers_o'length) and
                       (rb_triggers_r or repeat(global_trigger and all_triggers_are_global, rb_triggers_o'length));
      global_trigger_o <= global_trigger;  -- delay by 1 clock to align with event count
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Event Counter
  --------------------------------------------------------------------------------

  event_counter : entity work.event_counter
    port map (
      clk              => clk,
      rst_i            => reset or event_cnt_reset,
      global_trigger_i => global_trigger,
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
