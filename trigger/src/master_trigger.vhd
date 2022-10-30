-- TODO: LT format has changed from hit to 3 level thing, need to receive accordingly
--
-- FIXME: counters will multi-count pulse-extended hits

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.constants.all;
use work.components.all;
use work.registers.all;
use work.mt_types.all;
use work.types_pkg.all;
use work.ipbus.all;

library unisim;
use unisim.vcomponents.all;

-- CCB Schematics: http://ohm.bu.edu/~apeck/20220516_gaps_mt_data_package/20220516_GAPS_CCBv1/GAPS_CCBv1_docs/CCB_Schematics.pdf

entity gaps_mt is
  generic (
    EN_TMR_IPB_SLAVE_MT : integer range 0 to 1 := 0;

    MAC_ADDR : std_logic_vector (47 downto 0) := x"00_08_20_83_53_00";
    IP_ADDR  : ip_addr_t                      := (192, 168, 0, 10);

    LOOPBACK_MODE : boolean := true;

    MANCHESTER_LOOPBACK : boolean := true;

    -- these generics get set by hog at synthesis
    GLOBAL_DATE : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_TIME : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_VER  : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_SHA  : std_logic_vector (31 downto 0) := x"00000000";
    TOP_VER     : std_logic_vector (31 downto 0) := x"00000000";
    TOP_SHA     : std_logic_vector (31 downto 0) := x"00000000";
    HOG_SHA     : std_logic_vector (31 downto 0) := x"00000000";
    HOG_VER     : std_logic_vector (31 downto 0) := x"00000000"
    );
  port(

    -- CCB clock
    clk_p : in std_logic;
    clk_n : in std_logic;

    sys_clk_i : in std_logic; -- built-in 100Mhz callisto xo

    rst_button_i : in std_logic; -- built-in callisto reset button

    -- RGMII interface

    rgmii_mdio    : inout std_logic;
    rgmii_mdc     : inout std_logic;
    rgmii_int_n   : in    std_logic := '1';
    rgmii_reset_n : out   std_logic := '1';

    rgmii_clk125 : in std_logic;

    rgmii_rx_clk : in  std_logic;
    rgmii_rxd    : in  std_logic_vector(3 downto 0);
    rgmii_rx_ctl : in  std_logic;
    rgmii_tx_clk : out std_logic;
    rgmii_txd    : out std_logic_vector(3 downto 0);
    rgmii_tx_ctl : out std_logic;

    -- Local Trigger Data (LVDS)
    lt_data_i_p : in  std_logic_vector (NUM_LT_INPUTS-1 downto 0);
    lt_data_i_n : in  std_logic_vector (NUM_LT_INPUTS-1 downto 0);

    -- Readout Board Data LVCMOS
    rb_data_o   : out std_logic_vector (NUM_RB_OUTPUTS-1 downto 0);

    -- Feedback Clocks from DSIs
    fb_clk_p : in  std_logic_vector (NUM_DSI-1 downto 0);
    fb_clk_n : in  std_logic_vector (NUM_DSI-1 downto 0);

    -- DC/DC Syncs
    lvs_sync     : out std_logic_vector (NUM_DSI-1 downto 0);
    lvs_sync_ccb : out std_logic;

    -- DSI Control
    dsi_on       : out std_logic_vector (NUM_DSI-1 downto 0) := (others => '1');
    clk_src_sel  : out std_logic; -- 1 == ext clock

    -- housekeeping adcs
    hk_cs_n : out std_logic_vector(1 downto 0);
    hk_clk  : out std_logic;
    hk_dout : in  std_logic; -- master in, slave out
    hk_din  : out std_logic; -- master out, slave in

    ext_io  : inout std_logic_vector (13 downto 0);
    ext_out : out std_logic_vector (3 downto 0);
    ext_in  : in  std_logic_vector (3 downto 0);

    sump_o : out std_logic

    );
end gaps_mt;

architecture structural of gaps_mt is

  signal timestamp       : unsigned (47 downto 0) := (others => '0');
  signal timestamp_latch : unsigned (47 downto 0) := (others => '0');

  signal dsi_on_ipb  : std_logic_vector (dsi_on'range);
  signal trigger_ipb : std_logic := '0';

  signal rgmii_rxd_dly     : std_logic_vector(3 downto 0);
  signal rgmii_rx_ctl_dly  : std_logic := '0';
  signal rgmii_rx_clk_dly  : std_logic := '0';

  signal sys_clk : std_logic := '0';

  constant RGMII_RXD_DELAY : integer   := 0;
  constant RGMII_RXC_DELAY : integer   := 0;

  signal reset    : std_logic;
  signal reset_ff : std_logic_vector (1 downto 0);
  signal locked   : std_logic;

  signal clock : std_logic;

  signal clk25, clk100,  clk200,  clk125,  clk125_90 : std_logic;

  signal event_cnt     : std_logic_vector (EVENTCNTB-1 downto 0);
  signal rst_event_cnt : std_logic := '0';

  -- data/clk delays in units of 78 ps (0-31)
  --  use to align clock/data from a single LT
  signal fine_delays : lt_fine_delays_array_t
    := (others => (others => (others => '0')));
  signal coarse_delays : lt_coarse_delays_array_t
    := (others => (others => (others => '0')));
  signal posnegs : lt_posnegs_array_t
    := (others => (others => '0'));
  signal pulse_stretch : std_logic_vector (3 downto 0)
    := (others => '0');

  signal hit_mask      : lt_channel_array_t;  -- 2d array of 20x16 hit mask
  signal hit_mask_flat : channel_array_t;     -- 1d array of 320 hit mask

  signal hits, hits_masked : channel_array_t;     -- 1d array of 320 hits
  signal rb_hits           : rb_channel_array_t;  -- reshaped 2d array of 40x8 hits

  signal global_trigger : std_logic;  -- single bit == the baloon triggered somewhere

  signal trig_gen_rate   : std_logic_vector (31 downto 0) := (others => '0');
  signal trig_gen        : std_logic                      := '0';

  signal tiu_busy         : std_logic                     := '0';
  signal tiu_timebyte     : std_logic_vector (7 downto 0) := (others => '0');
  signal tiu_timebyte_dav : std_logic                     := '0';

  signal rb_triggers    : std_logic_vector (NUM_RBS-1 downto 0);  -- 1 bit trigger for each baloon
  signal triggers       : channel_array_t;                        -- 320 bits of trigger, one for each paddle

  signal fb_clk, fb_clk_i : std_logic_vector (fb_clk_p'range) := (others => '0');
  signal fb_clock_rates   : t_std32_array(fb_clk_p'range);

  signal clock_rate : std_logic_vector (31 downto 0) := (others => '0');

  -- xadc

  signal calibration : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpint     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpaux     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccoddr     : std_logic_vector(11 downto 0) := (others => '0');
  signal temp        : std_logic_vector(11 downto 0) := (others => '0');
  signal vccint      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccaux      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccbram     : std_logic_vector(11 downto 0) := (others => '0');

  --------------------------------------------------------------------------------
  -- IPbus / wishbone
  --------------------------------------------------------------------------------

  signal loopback : std_logic_vector (31 downto 0) := (others => '0');

  signal ipb_reset : std_logic;
  signal ipb_clk   : std_logic;

  signal eth_ipb_rbus : ipb_rbus;
  signal eth_ipb_wbus : ipb_wbus;

  constant IPB_MASTERS : integer := 1;

  signal ipb_masters_r_arr
    : ipb_rbus_array(IPB_MASTERS - 1 downto 0)
    := (others =>
        (ipb_rdata => (others => '0'),
         ipb_ack   => '0',
         ipb_err   => '0'));

  signal ipb_masters_w_arr : ipb_wbus_array(IPB_MASTERS - 1 downto 0);

  signal ipb_miso_arr
    : ipb_rbus_array(IPB_SLAVES - 1 downto 0)
    := (others =>
        (ipb_rdata => (others => '0'),
         ipb_ack   => '0',
         ipb_err   => '0'));

  signal ipb_mosi_arr : ipb_wbus_array(IPB_SLAVES - 1 downto 0);

  signal ipb_w : ipb_wbus;
  signal ipb_r : ipb_rbus;

  ------ Register signals begin (this section is generated by generate_registers.py -- do not edit)
  signal regs_read_arr        : t_std32_array(REG_MT_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_write_arr       : t_std32_array(REG_MT_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_addresses       : t_std32_array(REG_MT_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_defaults        : t_std32_array(REG_MT_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_read_pulse_arr  : std_logic_vector(REG_MT_NUM_REGS - 1 downto 0) := (others => '0');
  signal regs_write_pulse_arr : std_logic_vector(REG_MT_NUM_REGS - 1 downto 0) := (others => '0');
  signal regs_read_ready_arr  : std_logic_vector(REG_MT_NUM_REGS - 1 downto 0) := (others => '1');
  signal regs_write_done_arr  : std_logic_vector(REG_MT_NUM_REGS - 1 downto 0) := (others => '1');
  signal regs_writable_arr    : std_logic_vector(REG_MT_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
  signal hit_count_0 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_1 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_2 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_3 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_4 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_5 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_6 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_7 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_8 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_9 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_10 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_11 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_12 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_13 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_14 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_15 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_16 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_17 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_18 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_19 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_20 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_21 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_22 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_23 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_24 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_25 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_26 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_27 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_28 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_29 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_30 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_31 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_32 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_33 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_34 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_35 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_36 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_37 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_38 : std_logic_vector (15 downto 0) := (others => '0');
  signal hit_count_39 : std_logic_vector (15 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------

  signal hk_ext_cs_n : std_logic_vector(1 downto 0);
  signal hk_ext_clk  : std_logic;
  signal hk_ext_miso : std_logic; -- master in, slave out
  signal hk_ext_mosi  :std_logic; -- master out, slave in

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then
      reset_ff(0) <= not locked;
      reset_ff(1) <= reset_ff(0);
    end if;
  end process;

  reset <= not locked or reset_ff(1) or reset_ff(0);

  clk_src_sel <= '0';

  -- i2c_reset <= reset;
  ipb_reset     <= reset;
  ipb_clk       <= clock;
  clock         <= clk100;

  delayctrl_inst : IDELAYCTRL
    port map (
      RDY    => open,
      REFCLK => clk200,
      RST    => reset
      );

  eth_idelay_gen : for I in 0 to 3 generate
  begin
    idelay_inst : entity work.idelay
      generic map (PATTERN => "DATA")
      port map (
        clock => clk200,
        taps  => std_logic_vector(to_unsigned(RGMII_RXD_DELAY, 5)),
        din   => rgmii_rxd(I),
        dout  => rgmii_rxd_dly(I)
        );

  end generate;

  idelay_rx_ctl : entity work.idelay
    generic map (PATTERN => "DATA")
    port map (
      clock => clk200,
      taps  => std_logic_vector(to_unsigned(RGMII_RXD_DELAY, 5)),
      din   => rgmii_rx_ctl,
      dout  => rgmii_rx_ctl_dly
      );

  idelay_rx_clk : entity work.idelay
    generic map (PATTERN => "CLOCK")
    port map (
      clock => clk200,
      taps  => std_logic_vector(to_unsigned(RGMII_RXC_DELAY, 5)),
      din   => rgmii_rx_clk,
      dout  => rgmii_rx_clk_dly
      );

  eth_infra_inst : entity work.eth_infra
    port map (
      clock        => clock,
      reset        => reset,
      gtx_clk      => clk125,
      gtx_clk90    => clk125_90,

      rgmii_rx_clk => rgmii_rx_clk_dly,
      rgmii_rxd    => rgmii_rxd_dly,
      rgmii_rx_ctl => rgmii_rx_ctl_dly,
      rgmii_tx_clk => rgmii_tx_clk,
      rgmii_txd    => rgmii_txd,
      rgmii_tx_ctl => rgmii_tx_ctl,
      mac_addr     => MAC_ADDR,
      ip_addr      => to_slv(IP_ADDR),
      ipb_in       => ipb_masters_r_arr(0),
      ipb_out      => ipb_masters_w_arr(0)
      );

  --------------------------------------------------------------------------------
  -- arbiter to handle requests to/from 2 masters
  --------------------------------------------------------------------------------

  ipbus_arb_inst : entity work.ipbus_arb
    generic map (N_BUS => 1)
    port map (
      clk          => clock,
      rst          => reset,
      ipb_m_out    => ipb_masters_w_arr,
      ipb_m_in     => ipb_masters_r_arr,
      ipb_req(0)   => ipb_masters_w_arr(0).ipb_strobe,
      ipb_grant    => open,
      ipb_out      => ipb_w,
      ipb_in       => ipb_r
      );

  --------------------------------------------------------------------------------
  -- ipbus fabric selector
  --------------------------------------------------------------------------------

  fabric : entity work.ipbus_fabric_sel
    generic map(
      NSLV      => IPB_SLAVES,
      SEL_WIDTH => integer(ceil(log2(real(IPB_SLAVES))))
      )
    port map(
      ipb_in          => ipb_w,
      ipb_out         => ipb_r,
      sel             => std_logic_vector(
                          to_unsigned(ipb_addr_sel(ipb_w.ipb_addr),
                          integer(ceil(log2(real(IPB_SLAVES)))))),
      ipb_to_slaves   => ipb_mosi_arr,
      ipb_from_slaves => ipb_miso_arr
      );

  --------------------------------------------------------------------------------
  -- take in a global clock, generate system clocks at the correct frequency
  --------------------------------------------------------------------------------

  fb_clk_bufg : BUFG
    port map(
      i => sys_clk_i,
      o => sys_clk
      );

  clocking : entity work.clocking
    generic map (
      NUM_DSI => NUM_DSI
      )
    port map (
      clk_p     => clk_p,
      clk_n     => clk_n,

      lvs_sync => lvs_sync,
      ccb_sync => lvs_sync_ccb,

      clk25     => clk25,                -- system clock
      clk100    => clk100,               -- system clock
      clk200    => clk200,               -- 200mhz for iodelay
      clk125    => clk125,
      clk125_90 => clk125_90,
      locked    => locked               -- mmcm locked
      );

  fb_clk_gen : for I in fb_clk_p'range generate
  begin
    fb_clk_ibuf : IBUFDS
      port map(
        i  => fb_clk_p(I),
        ib => fb_clk_n(I),
        o  => fb_clk_i(I)
        );

    fb_clk_bufg : BUFG
      port map(
        i => fb_clk_i(I),
        o => fb_clk(I)
        );

  end generate;

  fb_clk_mon : for I in fb_clk'range generate
  begin
    frequency_counter_inst : entity work.frequency_counter
      generic map (
        clk_a_freq => 100000000
        )
      port map (
        reset => reset,
        clk_a => sys_clk,
        clk_b => fb_clk(I),
        rate  => fb_clock_rates(I)
        );
  end generate;

  frequency_counter_inst : entity work.frequency_counter
    generic map (
      clk_a_freq => 100000000
      )
    port map (
      reset => reset,
      clk_a => sys_clk,
      clk_b => clock,
      rate  => clock_rate
      );

  --------------------------------------------------------------------------------
  -- deserialize and align the inputs
  --------------------------------------------------------------------------------
  --
  -- lt data streams + delays --> vector of hits
  --
  --------------------------------------------------------------------------------

  noloop_r : if (not LOOPBACK_MODE) generate
    input_rx : entity work.input_rx
      port map (
        -- system clock
        clk    => clock,                  -- logic clock
        clk200 => clk200,                 -- for idelay

        -- clock and data from lt boards
        clocks_i => (others => clk100),
        data_i_p => lt_data_i_p,
        data_i_n => lt_data_i_n,

        -- -- idelay settings (in units of 80ps)
        -- clk_delays_i => clk_delays,

        -- sr delay settings (in units of 1 clock cycle)
        fine_delays_i   => fine_delays,
        coarse_delays_i => coarse_delays,
        posnegs_i       => posnegs,

        -- parameter to optionally stretch pulses
        pulse_stretch_i => pulse_stretch,

        -- hit outputs
        hits_o => hits
        );

    rb_hits       <= reshape(hits_masked);
    hit_mask_flat <= reshape(hit_mask);
    dsi_on        <= dsi_on_ipb;
  end generate;

  --------------------------------------------------------------------------------
  -- core trigger logic:
  --------------------------------------------------------------------------------
  --
  --   take in a list of hits on channels
  --   return a global OR of the trigger list
  --   and a list of channels to be read out
  --
  --------------------------------------------------------------------------------

  -- optionally mask off hot channels
  process (clock) is
  begin
    if (rising_edge(clock)) then
      for I in 0 to hits'length-1 loop
        hits_masked(I) <= hits(I) and hit_mask_flat(I);
      end loop;
    end if;
  end process;

  trigger : entity work.trigger
    port map (
      -- system clock
      clk => clock,

      -- hits from input stage (20x16 array of hits)
      hits_i => hits_masked,

      busy_i => tiu_busy,

      single_hit_en_i => '1',
      bool_trg_en_i   => '1',
      force_trigger_i => trigger_ipb or trig_gen,

      -- ouptut from trigger logic
      global_trigger_o => global_trigger,   -- OR of the trigger menu
      rb_triggers_o    => rb_triggers,     -- 40 trigger outputs  (1 per rb)
      triggers_o       => triggers         -- trigger output (320 trigger outputs)
      );

  -- Trigger generator
  trig_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clock,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => trig_gen_rate,
      trig       => trig_gen
      );

  --------------------------------------------------------------------------------
  -- event counter:
  --------------------------------------------------------------------------------
  --
  --
  --------------------------------------------------------------------------------

  event_counter : entity work.event_counter
    port map (
      clk              => clock,
      rst_i            => (reset) or rst_event_cnt,
      global_trigger_i => global_trigger,
    --trigger_i        => triggers,
      event_count_o    => event_cnt
      );

  --------------------------------------------------------------------------------
  -- trigger tx
  --------------------------------------------------------------------------------
  --
  -- takes in triggers, returns a serialized packet to send to the readout board
  --
  --------------------------------------------------------------------------------

  noloop_t : if (not LOOPBACK_MODE) generate
    trg_tx_gen : for I in 0 to NUM_RBS-1 generate
    begin
      trg_tx_inst : entity work.trg_tx
        generic map (
          EVENTCNTB => EVENTCNTB,
          MASKCNTB  => NUM_RB_CHANNELS
          )
        port map (
          clock       => clock,
          reset       => reset,
          serial_o    => rb_data_o(I),
          trg_i       => rb_triggers(I),
          resync_i    => '0',
          event_cnt_i => event_cnt,
          ch_mask_i   => rb_hits(I)
          );
    end generate;
  end generate;

  --------------------------------------------------------------------------------
  -- TIU Interface
  --------------------------------------------------------------------------------

  noloop_tiu : if (not LOOPBACK_MODE) generate

    signal event_cnt_wr_en  : std_logic                     := '0';
    signal tiu_trigger_o    : std_logic                     := '0';
    signal tiu_serial_o     : std_logic                     := '1';

    signal tiu_timecode_i    : std_logic                     := '0';
    signal tiu_timecode_sr   : std_logic_vector (2 downto 0) := (others => '0');
    signal tiu_falling       : std_logic                     := '0';

    constant TIU_CNT_MAX   : natural := 2**20-1;
    signal tiu_falling_cnt : natural := TIU_CNT_MAX;

    constant tiu_trig_cnt_max : natural   := 7;
    signal tiu_trig_cnt       : natural
      range 0 to tiu_trig_cnt_max := 0;

  begin

    tiu_trigger_o <= '1' when tiu_trig_cnt > 0 else '0';

    process (clock) is
    begin
      if (rising_edge(clock)) then
        if (global_trigger='1') then
          tiu_trig_cnt <= tiu_trig_cnt_max;
        elsif (tiu_trig_cnt > 0) then
          tiu_trig_cnt <= tiu_trig_cnt - 1;
        end if;
      end if;
    end process;

    -- delay by 1 to align with event cnt
    process (clock) is
    begin
      if (rising_edge(clock)) then
        event_cnt_wr_en <= global_trigger;
      end if;
    end process;

    tiu_tx_inst : entity work.tiu_tx
      generic map (
        EVENTCNTB => 32,
        DIV       => 100
        )
      port map (
        clock       => clock,
        reset       => reset,
        serial_o    => tiu_serial_o,
        trg_i       => event_cnt_wr_en,
        event_cnt_i => event_cnt
        );

    timecode_uart_inst : entity work.tiny_uart
      generic map (
        WLS    => 8,            --! word length select; number of data bits     [ integer ]
        CLK    => 100_000_000,  --! master clock frequency in Hz                [ integer ]
        BPS    => 9600,         --! transceive baud rate in Bps                 [ integer ]
        SBS    => 1,            --! Stop bit select, only one/two stopbit       [ integer ]
        PI     => true,         --! Parity inhibit, true: inhibit               [ boolean ]
        EPE    => true,         --! Even parity enable, true: even, false: odd  [ boolean ]
        DEBU   => 3,            --! Number of debouncer stages                  [ integer ]
        TXIMPL => false,        --! implement UART TX path                      [ boolean ]
        RXIMPL => true  )       --! implement UART RX path                      [ boolean ]
      port map (
        R    => reset,
        C    => clock,
        TXD  => open,
        RXD  => tiu_timecode_i,
        RR   => tiu_timebyte,
        PE   => open,
        FE   => open,
        DR   => tiu_timebyte_dav,
        TR   => (others => '0'),
        THRE => '0',
        THRL => '0',
        TRE  => open
        );

    -- on the falling edge of the tiu signal, latch the timecode

    process (clock) is
    begin
      if (rising_edge(clock)) then

        tiu_timecode_sr(0) <= tiu_timecode_i;

        for I in 0 to tiu_timecode_sr'length-1 loop
          tiu_timecode_sr(I) <= tiu_timecode_sr(I-1);
        end loop;

        tiu_falling <= '0';
        if (tiu_falling_cnt = 0 and tiu_timecode_sr(2) = '1' and tiu_timecode_sr(1) = '0') then
          tiu_falling <= '1';
          tiu_falling_cnt <= TIU_CNT_MAX;
        elsif (tiu_falling_cnt > 0) then
          tiu_falling_cnt <= tiu_falling_cnt - 1;
        end if;

        if (tiu_falling = '1') then
          timestamp_latch <= timestamp;
        end if;

      end if;
    end process;

  end generate;

  -------------------------------------------------------------------------------
  -- Timestamp
  -------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then
        timestamp <= (others => '0');
      else
        timestamp <= timestamp + 1;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- SPI master
  --------------------------------------------------------------------------------
  --
  -- MCP3208-BI/SL
  -- https://ww1.microchip.com/downloads/en/DeviceDoc/21298e.pdf
  -- https://opencores.org/websvn/filedetails?repname=spi&path=%2Fspi%2Ftrunk%2Fdoc%2Fspi.pdf
  ipbus_spi_inst : entity work.ipbus_spi
    generic map (
      N_SS => hk_ext_cs_n'length
      )
    port map (
      clk     => clock,
      rst     => reset,
      ipb_in  => ipb_mosi_arr(1),
      ipb_out => ipb_miso_arr(1),
      ss      => hk_ext_cs_n,
      mosi    => hk_ext_mosi,
      miso    => hk_ext_miso,
      sclk    => hk_ext_clk
      );

  ext_io(7) <= hk_ext_mosi;
  hk_ext_miso <= ext_io(6);
  ext_io(5) <= hk_ext_clk;
  ext_io(8) <= hk_ext_cs_n(0);
  ext_io(9) <= hk_ext_cs_n(1);

  --------------------------------------------------------------------------------
  -- Signal Sump
  --------------------------------------------------------------------------------

  sump_o <= global_trigger;

  --------------------------------------------------------------------------------
  -- Loopback Mode
  --------------------------------------------------------------------------------

  loopback_gen : if (LOOPBACK_MODE) generate
    constant CNT_WIDTH : integer := 10;

    type cnt_array_t is array (integer range <>)
      of std_logic_vector(CNT_WIDTH-1 downto 0);
    signal err_cnts        : cnt_array_t (lt_data_i_p'range);
    signal err_cnts_masked : cnt_array_t (lt_data_i_p'range);

    type inactivity_cnt_array_t is array (integer range <>)
      of integer range 0 to 63;
    signal inactivity_cnts : inactivity_cnt_array_t (lt_data_i_p'range);

    signal inactive : std_logic_vector(lt_data_i_p'range);

    signal frame_cnt : std_logic_vector(31 downto 0);

    signal data_o_src : std_logic := '0';

    signal prbs_reset          : std_logic := '0';
    signal data_gen            : std_logic := '0';
    signal data_gen_manchester : std_logic := '0';
    signal prbs_err            : std_logic_vector(lt_data_i_p'range);
    signal posneg_prbs         : std_logic_vector(lt_data_i_p'range);

    signal data_i_vec : std_logic_vector(lt_data_i_p'range);
    signal data_o_vec : std_logic_vector(rb_data_o'range);

    signal dsi_off_vio : std_logic_vector (dsi_on'range);

    signal prbs_clk_gate : std_logic := '1';

    constant DIV_MAX : natural                       := 128;
    signal div_vio   : std_logic_vector (2 downto 0) := (others => '0');
    signal div       : natural range 0 to DIV_MAX    := 0;
    signal clk_cnt   : natural range 0 to DIV_MAX    := 0;
    signal div_pulse   : std_logic                     := '0';

    signal prbs_err_inj_vio : std_logic := '0';
    signal prbs_err_inj_ff  : std_logic := '0';
    signal prbs_err_inj     : std_logic := '0';

    signal loopback_clk : std_logic := '0';

  begin

    loopback_clk <= clk25;

    -- for full speed, this should be a constant 1
    -- 
    -- for 1/2 speed, it should pulse for 1 clock cycle at the rising edge, 1
    -- clock cycle at the falling edge of the 50MHz divided (non-bufg) clock
    --
    -- 1/4, 1/8, 1/16 .... 1/128
    --
    -- etc
 
    prbs_clk_gate <= div_pulse;

    div <= 2**to_int(div_vio);

    process (loopback_clk) is
    begin
      if (rising_edge(loopback_clk)) then

        if (div=1) then
          div_pulse <= '1';
        elsif (div=2) then
          div_pulse <= not div_pulse;
        else
          if (clk_cnt = div-1) then
            clk_cnt <= 0;
          else
            clk_cnt <= clk_cnt + 1;
          end if;

          if (clk_cnt = 0 or clk_cnt = div/2) then
            div_pulse <= '1';
          else
            div_pulse <= '0';
          end if;
        end if;

      end if;
    end process;

    --------------------------------------------------------------------------------
    -- Control DSI through VIO when in loopback mode
    --------------------------------------------------------------------------------

    dsi_on <= not dsi_off_vio;

    --------------------------------------------------------------------------------
    -- PRBS-7 Data Generation
    -- Latency Pulse Data Generation
    --------------------------------------------------------------------------------

    prbs_any_gen : entity work.prbs_any
      generic map (
        chk_mode    => false,
        inv_pattern => false,
        poly_lenght => 7,
        poly_tap    => 6,
        nbits       => 1
        )
      port map (
        rst         => reset,
        clk         => loopback_clk,
        data_in(0)  => prbs_err_inj,
        en          => prbs_clk_gate,
        data_out(0) => data_gen
        );

    manchester_encoder_inst : entity work.manchester_encoder
      port map (
        clk    => loopback_clk,
        din    => data_gen,
        dout   => data_gen_manchester
        );

    -- output multiplexer
    process (data_gen, data_gen_manchester) is
    begin
      if (data_o_src = '0') then
        if (MANCHESTER_LOOPBACK) then
          rb_data_o <= (others => data_gen_manchester);
        end if;
        if (not MANCHESTER_LOOPBACK) then
          rb_data_o <= (others => data_gen);
        end if;
      else
        if (MANCHESTER_LOOPBACK) then
          rb_data_o <= repeat(loopback_clk, data_o_vec'length) xor data_o_vec;
        end if;
        if (not MANCHESTER_LOOPBACK) then
          rb_data_o <= data_o_vec;
        end if;
      end if;
    end process;

    process (loopback_clk) is
    begin
      if (rising_edge(loopback_clk)) then
        if (prbs_clk_gate = '1') then

          prbs_err_inj_ff <= prbs_err_inj_vio;

          if (prbs_err_inj_vio = '1') and (prbs_err_inj_ff = '0') then
            prbs_err_inj <= '1';
          else
            prbs_err_inj <= '0';
          end if;
        end if;
      end if;
    end process;


    input_gen : for I in lt_data_i_p'range generate
      signal data_pos   : std_logic := '0';
      signal data_neg   : std_logic := '0';
      signal data_neg_r : std_logic := '0';
      signal data       : std_logic := '0';
      signal lt_data_i  : std_logic := '0';
    begin

      ibufds_inst : ibufds
        generic map (
          diff_term    => true,  -- differential termination
          ibuf_low_pwr => true,  -- low power (true) vs. performance (false) setting for referenced i/o standards
          iostandard   => "default"
          )
        port map (
          o  => lt_data_i,      -- buffer output
          i  => lt_data_i_p(I), -- diff_p buffer input (connect directly to top-level port)
          ib => lt_data_i_n(I)  -- diff_n buffer input (connect directly to top-level port)
          );

      -- posedge
      process (loopback_clk) is
      begin
        if (rising_edge(loopback_clk)) then
          if (prbs_clk_gate = '1') then
            data_pos <= lt_data_i;
            data_neg <= data_neg_r;

            if (posneg_prbs(I) = '1') then
              data <= data_pos;
            else
              data <= data_neg;
            end if;

            data_i_vec(I) <= data;

          end if;
        end if;
      end process;

      -- negedge
      process (loopback_clk) is
      begin
        if (falling_edge(loopback_clk)) then
          if (prbs_clk_gate = '1') then
            data_neg_r <= lt_data_i;
          end if; 
        end if; 
      end process;

      --------------------------------------------------------------------------------
      -- PRBS-7 Checking
      --------------------------------------------------------------------------------

      prbs_any_check : entity work.prbs_any
        generic map (
          chk_mode    => true,
          inv_pattern => false,
          poly_lenght => 7,
          poly_tap    => 6,
          nbits       => 1
          )
        port map (
          rst         => reset,
          clk         => loopback_clk,
          data_in(0)  => data,
          en          => prbs_clk_gate,
          data_out(0) => prbs_err(I)
          );

      --------------------------------------------------------------------------------
      -- counters
      --------------------------------------------------------------------------------

      err_counter : entity work.counter_snap
        generic map (
          g_COUNTER_WIDTH  => CNT_WIDTH,
          g_ALLOW_ROLLOVER => false,
          g_INCREMENT_STEP => 1
          )
        port map (
          ref_clk_i => loopback_clk,
          reset_i   => reset or prbs_reset,
          en_i      => prbs_clk_gate and prbs_err(I),
          snap_i    => '1',
          count_o   => err_cnts(I)
          );

      process (loopback_clk) is
      begin
        if (rising_edge(loopback_clk)) then
          if (prbs_clk_gate = '1') then
            if (data /= data_i_vec(I)) then
              inactivity_cnts(I) <= 0;
              inactive(I)        <= '0';
            elsif (inactivity_cnts(I) = 63) then
              inactive(I) <= '1';
            elsif (inactivity_cnts(I) < 63) then
              inactivity_cnts(I) <= inactivity_cnts(I) + 1;
            end if;
          end if;
        end if;
      end process;


    end generate;

    frame_counter : entity work.counter_snap
      generic map (
        g_COUNTER_WIDTH  => frame_cnt'length,
        g_ALLOW_ROLLOVER => false,
        g_INCREMENT_STEP => 1
        )
      port map (
        ref_clk_i => loopback_clk,
        reset_i   => prbs_reset,
        en_i      => prbs_clk_gate,
        snap_i    => '1',
        count_o   => frame_cnt
        );

    ila_prbs_inst : ila_prbs
      port map (
        clk        => loopback_clk,
        probe0(0)  => prbs_clk_gate,
        probe1(0)  => data_gen,
        probe2     => data_i_vec,
        probe3     => std_logic_vector(to_unsigned(clk_cnt,8)),
        probe4     => std_logic_vector(to_unsigned(div,8)),
        probe5(0)  => lvs_sync_ccb,
        probe6(0)  => hk_ext_clk,
        probe7(0)  => hk_ext_mosi,
        probe8(0)  => hk_ext_miso,
        probe9     => hk_ext_cs_n,
        probe10    => fb_clk_rates(0),
        probe11    => fb_clk_rates(1),
        probe12    => fb_clk_rates(2),
        probe13    => fb_clk_rates(3),
        probe14    => fb_clk_rates(4)
        );

    mask_cnts_loop : for I in err_cnts'range generate
    begin
      err_cnts_masked(I) <= repeat(inactive(I), err_cnts(I)'length) or err_cnts(I);
    end generate;

    vio_prbs_inst : vio_prbs
      port map (
        clk           => loopback_clk,
        probe_in0     => frame_cnt,
        probe_in1     => err_cnts_masked(0),
        probe_in2     => err_cnts_masked(1),
        probe_in3     => err_cnts_masked(2),
        probe_in4     => err_cnts_masked(3),
        probe_in5     => err_cnts_masked(4),
        probe_in6     => err_cnts_masked(5),
        probe_in7     => err_cnts_masked(6),
        probe_in8     => err_cnts_masked(7),
        probe_in9     => err_cnts_masked(8),
        probe_in10    => err_cnts_masked(9),
        probe_in11    => err_cnts_masked(10),
        probe_in12    => err_cnts_masked(11),
        probe_in13    => err_cnts_masked(12),
        probe_in14    => err_cnts_masked(13),
        probe_in15    => err_cnts_masked(14),
        probe_in16    => err_cnts_masked(15),
        probe_in17    => err_cnts_masked(16),
        probe_in18    => err_cnts_masked(17),
        probe_in19    => err_cnts_masked(18),
        probe_in20    => err_cnts_masked(19),
        probe_in21    => err_cnts_masked(20),
        probe_in22    => err_cnts_masked(21),
        probe_in23    => err_cnts_masked(22),
        probe_in24    => err_cnts_masked(23),
        probe_in25    => err_cnts_masked(24),
        probe_in26    => err_cnts_masked(25),
        probe_in27    => err_cnts_masked(26),
        probe_in28    => err_cnts_masked(27),
        probe_in29    => err_cnts_masked(28),
        probe_in30    => err_cnts_masked(29),
        probe_in31    => err_cnts_masked(30),
        probe_in32    => err_cnts_masked(31),
        probe_in33    => err_cnts_masked(32),
        probe_in34    => err_cnts_masked(33),
        probe_in35    => err_cnts_masked(34),
        probe_in36    => err_cnts_masked(35),
        probe_in37    => err_cnts_masked(36),
        probe_in38    => err_cnts_masked(37),
        probe_in39    => err_cnts_masked(38),
        probe_in40    => err_cnts_masked(39),
        probe_in41    => err_cnts_masked(40),
        probe_in42    => err_cnts_masked(41),
        probe_in43    => err_cnts_masked(42),
        probe_in44    => err_cnts_masked(43),
        probe_in45    => err_cnts_masked(44),
        probe_in46    => err_cnts_masked(45),
        probe_in47    => err_cnts_masked(46),
        probe_in48    => err_cnts_masked(47),
        probe_in49    => err_cnts_masked(48),
        probe_in50    => err_cnts_masked(49),
        probe_in51    => err_cnts_masked(50),
        probe_in52    => err_cnts_masked(51),
        probe_in53    => err_cnts_masked(52),
        probe_in54    => err_cnts_masked(53),
        probe_in55    => err_cnts_masked(54),
        probe_in56    => err_cnts_masked(55),
        probe_in57    => err_cnts_masked(56),
        probe_in58    => err_cnts_masked(57),
        probe_in59    => err_cnts_masked(58),
        probe_in60    => err_cnts_masked(59),
        probe_in61    => err_cnts_masked(60),
        probe_in62    => err_cnts_masked(61),
        probe_in63    => err_cnts_masked(62),
        probe_in64    => err_cnts_masked(63),
        probe_in65    => err_cnts_masked(64),
        probe_in66    => err_cnts_masked(65),
        probe_in67    => err_cnts_masked(66),
        probe_in68    => err_cnts_masked(67),
        probe_in69    => err_cnts_masked(68),
        probe_in70    => err_cnts_masked(69),
        probe_in71    => err_cnts_masked(70),
        probe_in72    => err_cnts_masked(71),
        probe_in73    => err_cnts_masked(72),
        probe_in74    => err_cnts_masked(73),
        probe_in75    => err_cnts_masked(74),
        probe_in76    => data_i_vec,
        probe_in77    => ext_in,
        probe_out0(0) => prbs_reset,
        probe_out1    => posneg_prbs,
        probe_out2    => data_o_vec,
        probe_out3(0) => data_o_src,
        probe_out4    => dsi_off_vio,
        probe_out5    => ext_out,
        probe_out6    => div_vio,
        probe_out7(0) => prbs_err_inj_vio
        );

  end generate;

  --------------------------------------------------------------------------------
  -- Single Event Correction
  --------------------------------------------------------------------------------

  sem_wrapper : entity work.sem_wrapper
    port map (
      clk_i            => clock,
      correction_o     => open, -- sem_correction,
      classification_o => open,
      uncorrectable_o  => open, -- sem_uncorrectable_error,
      heartbeat_o      => open,
      initialization_o => open,
      observation_o    => open,
      essential_o      => open,
      sump             => open
      );

  --------------------------------------------------------------------------------
  -- XADC
  --------------------------------------------------------------------------------

  adc_inst : entity work.adc
    port map (
      clock       => clock,
      reset       => reset,
      calibration => calibration,
      vccpint     => vccpint,
      vccpaux     => vccpaux,
      vccoddr     => vccoddr,
      temp        => temp,
      vccint      => vccint,
      vccaux      => vccaux,
      vccbram     => vccbram
      );

  ----------------------------------------------------------------------------------
  --
  -- beyond this is generated by tools/generate_registers.py -- do not edit
  --
  ----------------------------------------------------------------------------------
  --
  --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
  ipbus_slave_inst : entity work.ipbus_slave_tmr
      generic map(
         g_ENABLE_TMR           => EN_TMR_IPB_SLAVE_MT,
         g_NUM_REGS             => REG_MT_NUM_REGS,
         g_ADDR_HIGH_BIT        => REG_MT_ADDRESS_MSB,
         g_ADDR_LOW_BIT         => REG_MT_ADDRESS_LSB,
         g_USE_INDIVIDUAL_ADDRS => true
     )
     port map(
         ipb_reset_i            => ipb_reset,
         ipb_clk_i              => ipb_clk,
         ipb_mosi_i             => ipb_mosi_arr(0),
         ipb_miso_o             => ipb_miso_arr(0),
         usr_clk_i              => clock,
         regs_read_arr_i        => regs_read_arr,
         regs_write_arr_o       => regs_write_arr,
         read_pulse_arr_o       => regs_read_pulse_arr,
         write_pulse_arr_o      => regs_write_pulse_arr,
         regs_read_ready_arr_i  => regs_read_ready_arr,
         regs_write_done_arr_i  => regs_write_done_arr,
         individual_addrs_arr_i => regs_addresses,
         regs_defaults_arr_i    => regs_defaults,
         writable_regs_i        => regs_writable_arr
    );

  -- Addresses
  regs_addresses(0)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"00";
  regs_addresses(1)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"01";
  regs_addresses(2)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"02";
  regs_addresses(3)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"03";
  regs_addresses(4)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"04";
  regs_addresses(5)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"05";
  regs_addresses(6)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"06";
  regs_addresses(7)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"07";
  regs_addresses(8)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"08";
  regs_addresses(9)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"09";
  regs_addresses(10)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0f";
  regs_addresses(11)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"10";
  regs_addresses(12)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"11";
  regs_addresses(13)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"12";
  regs_addresses(14)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"13";
  regs_addresses(15)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"14";
  regs_addresses(16)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"15";
  regs_addresses(17)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"16";
  regs_addresses(18)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"17";
  regs_addresses(19)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"18";
  regs_addresses(20)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"19";
  regs_addresses(21)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1a";
  regs_addresses(22)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1b";
  regs_addresses(23)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1c";
  regs_addresses(24)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1d";
  regs_addresses(25)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1e";
  regs_addresses(26)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1f";
  regs_addresses(27)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"20";
  regs_addresses(28)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"21";
  regs_addresses(29)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"22";
  regs_addresses(30)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"23";
  regs_addresses(31)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"24";
  regs_addresses(32)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"25";
  regs_addresses(33)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"26";
  regs_addresses(34)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"27";
  regs_addresses(35)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"28";
  regs_addresses(36)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"29";
  regs_addresses(37)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2a";
  regs_addresses(38)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2b";
  regs_addresses(39)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2c";
  regs_addresses(40)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2d";
  regs_addresses(41)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2e";
  regs_addresses(42)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2f";
  regs_addresses(43)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"30";
  regs_addresses(44)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"31";
  regs_addresses(45)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"32";
  regs_addresses(46)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"33";
  regs_addresses(47)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"34";
  regs_addresses(48)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"35";
  regs_addresses(49)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"36";
  regs_addresses(50)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"37";
  regs_addresses(51)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"40";
  regs_addresses(52)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"41";
  regs_addresses(53)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"42";
  regs_addresses(54)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"43";
  regs_addresses(55)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"44";
  regs_addresses(56)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"45";
  regs_addresses(57)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"46";
  regs_addresses(58)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"47";
  regs_addresses(59)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"48";
  regs_addresses(60)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"49";
  regs_addresses(61)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4a";
  regs_addresses(62)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4b";
  regs_addresses(63)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4c";
  regs_addresses(64)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4d";
  regs_addresses(65)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4e";
  regs_addresses(66)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"4f";
  regs_addresses(67)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"50";
  regs_addresses(68)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"51";
  regs_addresses(69)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"52";
  regs_addresses(70)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"53";
  regs_addresses(71)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"60";
  regs_addresses(72)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"61";
  regs_addresses(73)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"62";
  regs_addresses(74)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"63";
  regs_addresses(75)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"64";
  regs_addresses(76)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"65";
  regs_addresses(77)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"66";
  regs_addresses(78)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"67";
  regs_addresses(79)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"68";
  regs_addresses(80)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"69";
  regs_addresses(81)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6a";
  regs_addresses(82)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6b";
  regs_addresses(83)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6c";
  regs_addresses(84)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6d";
  regs_addresses(85)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6e";
  regs_addresses(86)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"6f";
  regs_addresses(87)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"70";
  regs_addresses(88)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"71";
  regs_addresses(89)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"72";
  regs_addresses(90)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"73";
  regs_addresses(91)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"80";
  regs_addresses(92)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"81";
  regs_addresses(93)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"82";
  regs_addresses(94)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"83";
  regs_addresses(95)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"84";
  regs_addresses(96)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"85";
  regs_addresses(97)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"86";
  regs_addresses(98)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"87";
  regs_addresses(99)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"88";
  regs_addresses(100)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"89";
  regs_addresses(101)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8a";
  regs_addresses(102)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8b";
  regs_addresses(103)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8c";
  regs_addresses(104)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8d";
  regs_addresses(105)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8e";
  regs_addresses(106)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8f";
  regs_addresses(107)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"90";
  regs_addresses(108)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"91";
  regs_addresses(109)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"92";
  regs_addresses(110)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"93";
  regs_addresses(111)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"00";
  regs_addresses(112)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"01";
  regs_addresses(113)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"02";
  regs_addresses(114)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"03";
  regs_addresses(115)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"04";
  regs_addresses(116)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"05";
  regs_addresses(117)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"06";
  regs_addresses(118)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"07";
  regs_addresses(119)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"08";
  regs_addresses(120)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"09";
  regs_addresses(121)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0a";
  regs_addresses(122)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0b";
  regs_addresses(123)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0c";
  regs_addresses(124)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0d";
  regs_addresses(125)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0e";
  regs_addresses(126)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0f";
  regs_addresses(127)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"10";
  regs_addresses(128)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"11";
  regs_addresses(129)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"12";
  regs_addresses(130)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"13";
  regs_addresses(131)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"20";
  regs_addresses(132)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"21";
  regs_addresses(133)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"22";
  regs_addresses(134)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"23";
  regs_addresses(135)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"00";
  regs_addresses(136)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"01";
  regs_addresses(137)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"02";
  regs_addresses(138)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"03";
  regs_addresses(139)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"04";
  regs_addresses(140)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"05";
  regs_addresses(141)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"06";
  regs_addresses(142)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"07";

  -- Connect read signals
  regs_read_arr(0)(REG_MT_LOOPBACK_MSB downto REG_MT_LOOPBACK_LSB) <= loopback;
  regs_read_arr(1)(REG_MT_CLOCK_RATE_MSB downto REG_MT_CLOCK_RATE_LSB) <= clock_rate;
  regs_read_arr(2)(REG_MT_FB_CLOCK_RATE_0_MSB downto REG_MT_FB_CLOCK_RATE_0_LSB) <= fb_clock_rates(0);
  regs_read_arr(3)(REG_MT_FB_CLOCK_RATE_1_MSB downto REG_MT_FB_CLOCK_RATE_1_LSB) <= fb_clock_rates(1);
  regs_read_arr(4)(REG_MT_FB_CLOCK_RATE_2_MSB downto REG_MT_FB_CLOCK_RATE_2_LSB) <= fb_clock_rates(2);
  regs_read_arr(5)(REG_MT_FB_CLOCK_RATE_3_MSB downto REG_MT_FB_CLOCK_RATE_3_LSB) <= fb_clock_rates(3);
  regs_read_arr(6)(REG_MT_FB_CLOCK_RATE_4_MSB downto REG_MT_FB_CLOCK_RATE_4_LSB) <= fb_clock_rates(4);
  regs_read_arr(7)(REG_MT_DSI_ON_MSB downto REG_MT_DSI_ON_LSB) <= dsi_on_ipb;
  regs_read_arr(9)(REG_MT_TRIG_GEN_RATE_MSB downto REG_MT_TRIG_GEN_RATE_LSB) <= trig_gen_rate;
  regs_read_arr(10)(REG_MT_PULSE_STRETCH_MSB downto REG_MT_PULSE_STRETCH_LSB) <= pulse_stretch;
  regs_read_arr(11)(REG_MT_HIT_COUNTERS_RB0_MSB downto REG_MT_HIT_COUNTERS_RB0_LSB) <= hit_count_0;
  regs_read_arr(12)(REG_MT_HIT_COUNTERS_RB1_MSB downto REG_MT_HIT_COUNTERS_RB1_LSB) <= hit_count_1;
  regs_read_arr(13)(REG_MT_HIT_COUNTERS_RB2_MSB downto REG_MT_HIT_COUNTERS_RB2_LSB) <= hit_count_2;
  regs_read_arr(14)(REG_MT_HIT_COUNTERS_RB3_MSB downto REG_MT_HIT_COUNTERS_RB3_LSB) <= hit_count_3;
  regs_read_arr(15)(REG_MT_HIT_COUNTERS_RB4_MSB downto REG_MT_HIT_COUNTERS_RB4_LSB) <= hit_count_4;
  regs_read_arr(16)(REG_MT_HIT_COUNTERS_RB5_MSB downto REG_MT_HIT_COUNTERS_RB5_LSB) <= hit_count_5;
  regs_read_arr(17)(REG_MT_HIT_COUNTERS_RB6_MSB downto REG_MT_HIT_COUNTERS_RB6_LSB) <= hit_count_6;
  regs_read_arr(18)(REG_MT_HIT_COUNTERS_RB7_MSB downto REG_MT_HIT_COUNTERS_RB7_LSB) <= hit_count_7;
  regs_read_arr(19)(REG_MT_HIT_COUNTERS_RB8_MSB downto REG_MT_HIT_COUNTERS_RB8_LSB) <= hit_count_8;
  regs_read_arr(20)(REG_MT_HIT_COUNTERS_RB9_MSB downto REG_MT_HIT_COUNTERS_RB9_LSB) <= hit_count_9;
  regs_read_arr(21)(REG_MT_HIT_COUNTERS_RB10_MSB downto REG_MT_HIT_COUNTERS_RB10_LSB) <= hit_count_10;
  regs_read_arr(22)(REG_MT_HIT_COUNTERS_RB11_MSB downto REG_MT_HIT_COUNTERS_RB11_LSB) <= hit_count_11;
  regs_read_arr(23)(REG_MT_HIT_COUNTERS_RB12_MSB downto REG_MT_HIT_COUNTERS_RB12_LSB) <= hit_count_12;
  regs_read_arr(24)(REG_MT_HIT_COUNTERS_RB13_MSB downto REG_MT_HIT_COUNTERS_RB13_LSB) <= hit_count_13;
  regs_read_arr(25)(REG_MT_HIT_COUNTERS_RB14_MSB downto REG_MT_HIT_COUNTERS_RB14_LSB) <= hit_count_14;
  regs_read_arr(26)(REG_MT_HIT_COUNTERS_RB15_MSB downto REG_MT_HIT_COUNTERS_RB15_LSB) <= hit_count_15;
  regs_read_arr(27)(REG_MT_HIT_COUNTERS_RB16_MSB downto REG_MT_HIT_COUNTERS_RB16_LSB) <= hit_count_16;
  regs_read_arr(28)(REG_MT_HIT_COUNTERS_RB17_MSB downto REG_MT_HIT_COUNTERS_RB17_LSB) <= hit_count_17;
  regs_read_arr(29)(REG_MT_HIT_COUNTERS_RB18_MSB downto REG_MT_HIT_COUNTERS_RB18_LSB) <= hit_count_18;
  regs_read_arr(30)(REG_MT_HIT_COUNTERS_RB19_MSB downto REG_MT_HIT_COUNTERS_RB19_LSB) <= hit_count_19;
  regs_read_arr(31)(REG_MT_HIT_COUNTERS_RB20_MSB downto REG_MT_HIT_COUNTERS_RB20_LSB) <= hit_count_20;
  regs_read_arr(32)(REG_MT_HIT_COUNTERS_RB21_MSB downto REG_MT_HIT_COUNTERS_RB21_LSB) <= hit_count_21;
  regs_read_arr(33)(REG_MT_HIT_COUNTERS_RB22_MSB downto REG_MT_HIT_COUNTERS_RB22_LSB) <= hit_count_22;
  regs_read_arr(34)(REG_MT_HIT_COUNTERS_RB23_MSB downto REG_MT_HIT_COUNTERS_RB23_LSB) <= hit_count_23;
  regs_read_arr(35)(REG_MT_HIT_COUNTERS_RB24_MSB downto REG_MT_HIT_COUNTERS_RB24_LSB) <= hit_count_24;
  regs_read_arr(36)(REG_MT_HIT_COUNTERS_RB25_MSB downto REG_MT_HIT_COUNTERS_RB25_LSB) <= hit_count_25;
  regs_read_arr(37)(REG_MT_HIT_COUNTERS_RB26_MSB downto REG_MT_HIT_COUNTERS_RB26_LSB) <= hit_count_26;
  regs_read_arr(38)(REG_MT_HIT_COUNTERS_RB27_MSB downto REG_MT_HIT_COUNTERS_RB27_LSB) <= hit_count_27;
  regs_read_arr(39)(REG_MT_HIT_COUNTERS_RB28_MSB downto REG_MT_HIT_COUNTERS_RB28_LSB) <= hit_count_28;
  regs_read_arr(40)(REG_MT_HIT_COUNTERS_RB29_MSB downto REG_MT_HIT_COUNTERS_RB29_LSB) <= hit_count_29;
  regs_read_arr(41)(REG_MT_HIT_COUNTERS_RB30_MSB downto REG_MT_HIT_COUNTERS_RB30_LSB) <= hit_count_30;
  regs_read_arr(42)(REG_MT_HIT_COUNTERS_RB31_MSB downto REG_MT_HIT_COUNTERS_RB31_LSB) <= hit_count_31;
  regs_read_arr(43)(REG_MT_HIT_COUNTERS_RB32_MSB downto REG_MT_HIT_COUNTERS_RB32_LSB) <= hit_count_32;
  regs_read_arr(44)(REG_MT_HIT_COUNTERS_RB33_MSB downto REG_MT_HIT_COUNTERS_RB33_LSB) <= hit_count_33;
  regs_read_arr(45)(REG_MT_HIT_COUNTERS_RB34_MSB downto REG_MT_HIT_COUNTERS_RB34_LSB) <= hit_count_34;
  regs_read_arr(46)(REG_MT_HIT_COUNTERS_RB35_MSB downto REG_MT_HIT_COUNTERS_RB35_LSB) <= hit_count_35;
  regs_read_arr(47)(REG_MT_HIT_COUNTERS_RB36_MSB downto REG_MT_HIT_COUNTERS_RB36_LSB) <= hit_count_36;
  regs_read_arr(48)(REG_MT_HIT_COUNTERS_RB37_MSB downto REG_MT_HIT_COUNTERS_RB37_LSB) <= hit_count_37;
  regs_read_arr(49)(REG_MT_HIT_COUNTERS_RB38_MSB downto REG_MT_HIT_COUNTERS_RB38_LSB) <= hit_count_38;
  regs_read_arr(50)(REG_MT_HIT_COUNTERS_RB39_MSB downto REG_MT_HIT_COUNTERS_RB39_LSB) <= hit_count_39;
  regs_read_arr(51)(REG_MT_HIT_MASK_LT0_MSB downto REG_MT_HIT_MASK_LT0_LSB) <= hit_mask(0);
  regs_read_arr(52)(REG_MT_HIT_MASK_LT1_MSB downto REG_MT_HIT_MASK_LT1_LSB) <= hit_mask(1);
  regs_read_arr(53)(REG_MT_HIT_MASK_LT2_MSB downto REG_MT_HIT_MASK_LT2_LSB) <= hit_mask(2);
  regs_read_arr(54)(REG_MT_HIT_MASK_LT3_MSB downto REG_MT_HIT_MASK_LT3_LSB) <= hit_mask(3);
  regs_read_arr(55)(REG_MT_HIT_MASK_LT4_MSB downto REG_MT_HIT_MASK_LT4_LSB) <= hit_mask(4);
  regs_read_arr(56)(REG_MT_HIT_MASK_LT5_MSB downto REG_MT_HIT_MASK_LT5_LSB) <= hit_mask(5);
  regs_read_arr(57)(REG_MT_HIT_MASK_LT6_MSB downto REG_MT_HIT_MASK_LT6_LSB) <= hit_mask(6);
  regs_read_arr(58)(REG_MT_HIT_MASK_LT7_MSB downto REG_MT_HIT_MASK_LT7_LSB) <= hit_mask(7);
  regs_read_arr(59)(REG_MT_HIT_MASK_LT8_MSB downto REG_MT_HIT_MASK_LT8_LSB) <= hit_mask(8);
  regs_read_arr(60)(REG_MT_HIT_MASK_LT9_MSB downto REG_MT_HIT_MASK_LT9_LSB) <= hit_mask(9);
  regs_read_arr(61)(REG_MT_HIT_MASK_LT10_MSB downto REG_MT_HIT_MASK_LT10_LSB) <= hit_mask(10);
  regs_read_arr(62)(REG_MT_HIT_MASK_LT11_MSB downto REG_MT_HIT_MASK_LT11_LSB) <= hit_mask(11);
  regs_read_arr(63)(REG_MT_HIT_MASK_LT12_MSB downto REG_MT_HIT_MASK_LT12_LSB) <= hit_mask(12);
  regs_read_arr(64)(REG_MT_HIT_MASK_LT13_MSB downto REG_MT_HIT_MASK_LT13_LSB) <= hit_mask(13);
  regs_read_arr(65)(REG_MT_HIT_MASK_LT14_MSB downto REG_MT_HIT_MASK_LT14_LSB) <= hit_mask(14);
  regs_read_arr(66)(REG_MT_HIT_MASK_LT15_MSB downto REG_MT_HIT_MASK_LT15_LSB) <= hit_mask(15);
  regs_read_arr(67)(REG_MT_HIT_MASK_LT16_MSB downto REG_MT_HIT_MASK_LT16_LSB) <= hit_mask(16);
  regs_read_arr(68)(REG_MT_HIT_MASK_LT17_MSB downto REG_MT_HIT_MASK_LT17_LSB) <= hit_mask(17);
  regs_read_arr(69)(REG_MT_HIT_MASK_LT18_MSB downto REG_MT_HIT_MASK_LT18_LSB) <= hit_mask(18);
  regs_read_arr(70)(REG_MT_HIT_MASK_LT19_MSB downto REG_MT_HIT_MASK_LT19_LSB) <= hit_mask(19);
  regs_read_arr(71)(REG_MT_FINE_DELAYS_LT0_CH0_MSB downto REG_MT_FINE_DELAYS_LT0_CH0_LSB) <= fine_delays(0)(0);
  regs_read_arr(71)(REG_MT_FINE_DELAYS_LT0_CH1_MSB downto REG_MT_FINE_DELAYS_LT0_CH1_LSB) <= fine_delays(0)(1);
  regs_read_arr(72)(REG_MT_FINE_DELAYS_LT1_CH0_MSB downto REG_MT_FINE_DELAYS_LT1_CH0_LSB) <= fine_delays(1)(0);
  regs_read_arr(72)(REG_MT_FINE_DELAYS_LT1_CH1_MSB downto REG_MT_FINE_DELAYS_LT1_CH1_LSB) <= fine_delays(1)(1);
  regs_read_arr(73)(REG_MT_FINE_DELAYS_LT2_CH0_MSB downto REG_MT_FINE_DELAYS_LT2_CH0_LSB) <= fine_delays(2)(0);
  regs_read_arr(73)(REG_MT_FINE_DELAYS_LT2_CH1_MSB downto REG_MT_FINE_DELAYS_LT2_CH1_LSB) <= fine_delays(2)(1);
  regs_read_arr(74)(REG_MT_FINE_DELAYS_LT3_CH0_MSB downto REG_MT_FINE_DELAYS_LT3_CH0_LSB) <= fine_delays(3)(0);
  regs_read_arr(74)(REG_MT_FINE_DELAYS_LT3_CH1_MSB downto REG_MT_FINE_DELAYS_LT3_CH1_LSB) <= fine_delays(3)(1);
  regs_read_arr(75)(REG_MT_FINE_DELAYS_LT4_CH0_MSB downto REG_MT_FINE_DELAYS_LT4_CH0_LSB) <= fine_delays(4)(0);
  regs_read_arr(75)(REG_MT_FINE_DELAYS_LT4_CH1_MSB downto REG_MT_FINE_DELAYS_LT4_CH1_LSB) <= fine_delays(4)(1);
  regs_read_arr(76)(REG_MT_FINE_DELAYS_LT5_CH0_MSB downto REG_MT_FINE_DELAYS_LT5_CH0_LSB) <= fine_delays(5)(0);
  regs_read_arr(76)(REG_MT_FINE_DELAYS_LT5_CH1_MSB downto REG_MT_FINE_DELAYS_LT5_CH1_LSB) <= fine_delays(5)(1);
  regs_read_arr(77)(REG_MT_FINE_DELAYS_LT6_CH0_MSB downto REG_MT_FINE_DELAYS_LT6_CH0_LSB) <= fine_delays(6)(0);
  regs_read_arr(77)(REG_MT_FINE_DELAYS_LT6_CH1_MSB downto REG_MT_FINE_DELAYS_LT6_CH1_LSB) <= fine_delays(6)(1);
  regs_read_arr(78)(REG_MT_FINE_DELAYS_LT7_CH0_MSB downto REG_MT_FINE_DELAYS_LT7_CH0_LSB) <= fine_delays(7)(0);
  regs_read_arr(78)(REG_MT_FINE_DELAYS_LT7_CH1_MSB downto REG_MT_FINE_DELAYS_LT7_CH1_LSB) <= fine_delays(7)(1);
  regs_read_arr(79)(REG_MT_FINE_DELAYS_LT8_CH0_MSB downto REG_MT_FINE_DELAYS_LT8_CH0_LSB) <= fine_delays(8)(0);
  regs_read_arr(79)(REG_MT_FINE_DELAYS_LT8_CH1_MSB downto REG_MT_FINE_DELAYS_LT8_CH1_LSB) <= fine_delays(8)(1);
  regs_read_arr(80)(REG_MT_FINE_DELAYS_LT9_CH0_MSB downto REG_MT_FINE_DELAYS_LT9_CH0_LSB) <= fine_delays(9)(0);
  regs_read_arr(80)(REG_MT_FINE_DELAYS_LT9_CH1_MSB downto REG_MT_FINE_DELAYS_LT9_CH1_LSB) <= fine_delays(9)(1);
  regs_read_arr(81)(REG_MT_FINE_DELAYS_LT10_CH0_MSB downto REG_MT_FINE_DELAYS_LT10_CH0_LSB) <= fine_delays(10)(0);
  regs_read_arr(81)(REG_MT_FINE_DELAYS_LT10_CH1_MSB downto REG_MT_FINE_DELAYS_LT10_CH1_LSB) <= fine_delays(10)(1);
  regs_read_arr(82)(REG_MT_FINE_DELAYS_LT11_CH0_MSB downto REG_MT_FINE_DELAYS_LT11_CH0_LSB) <= fine_delays(11)(0);
  regs_read_arr(82)(REG_MT_FINE_DELAYS_LT11_CH1_MSB downto REG_MT_FINE_DELAYS_LT11_CH1_LSB) <= fine_delays(11)(1);
  regs_read_arr(83)(REG_MT_FINE_DELAYS_LT12_CH0_MSB downto REG_MT_FINE_DELAYS_LT12_CH0_LSB) <= fine_delays(12)(0);
  regs_read_arr(83)(REG_MT_FINE_DELAYS_LT12_CH1_MSB downto REG_MT_FINE_DELAYS_LT12_CH1_LSB) <= fine_delays(12)(1);
  regs_read_arr(84)(REG_MT_FINE_DELAYS_LT13_CH0_MSB downto REG_MT_FINE_DELAYS_LT13_CH0_LSB) <= fine_delays(13)(0);
  regs_read_arr(84)(REG_MT_FINE_DELAYS_LT13_CH1_MSB downto REG_MT_FINE_DELAYS_LT13_CH1_LSB) <= fine_delays(13)(1);
  regs_read_arr(85)(REG_MT_FINE_DELAYS_LT14_CH0_MSB downto REG_MT_FINE_DELAYS_LT14_CH0_LSB) <= fine_delays(14)(0);
  regs_read_arr(85)(REG_MT_FINE_DELAYS_LT14_CH1_MSB downto REG_MT_FINE_DELAYS_LT14_CH1_LSB) <= fine_delays(14)(1);
  regs_read_arr(86)(REG_MT_FINE_DELAYS_LT15_CH0_MSB downto REG_MT_FINE_DELAYS_LT15_CH0_LSB) <= fine_delays(15)(0);
  regs_read_arr(86)(REG_MT_FINE_DELAYS_LT15_CH1_MSB downto REG_MT_FINE_DELAYS_LT15_CH1_LSB) <= fine_delays(15)(1);
  regs_read_arr(87)(REG_MT_FINE_DELAYS_LT16_CH0_MSB downto REG_MT_FINE_DELAYS_LT16_CH0_LSB) <= fine_delays(16)(0);
  regs_read_arr(87)(REG_MT_FINE_DELAYS_LT16_CH1_MSB downto REG_MT_FINE_DELAYS_LT16_CH1_LSB) <= fine_delays(16)(1);
  regs_read_arr(88)(REG_MT_FINE_DELAYS_LT17_CH0_MSB downto REG_MT_FINE_DELAYS_LT17_CH0_LSB) <= fine_delays(17)(0);
  regs_read_arr(88)(REG_MT_FINE_DELAYS_LT17_CH1_MSB downto REG_MT_FINE_DELAYS_LT17_CH1_LSB) <= fine_delays(17)(1);
  regs_read_arr(89)(REG_MT_FINE_DELAYS_LT18_CH0_MSB downto REG_MT_FINE_DELAYS_LT18_CH0_LSB) <= fine_delays(18)(0);
  regs_read_arr(89)(REG_MT_FINE_DELAYS_LT18_CH1_MSB downto REG_MT_FINE_DELAYS_LT18_CH1_LSB) <= fine_delays(18)(1);
  regs_read_arr(90)(REG_MT_FINE_DELAYS_LT19_CH0_MSB downto REG_MT_FINE_DELAYS_LT19_CH0_LSB) <= fine_delays(19)(0);
  regs_read_arr(90)(REG_MT_FINE_DELAYS_LT19_CH1_MSB downto REG_MT_FINE_DELAYS_LT19_CH1_LSB) <= fine_delays(19)(1);
  regs_read_arr(91)(REG_MT_COARSE_DELAYS_LT0_CH0_MSB downto REG_MT_COARSE_DELAYS_LT0_CH0_LSB) <= coarse_delays(0)(0);
  regs_read_arr(91)(REG_MT_COARSE_DELAYS_LT0_CH1_MSB downto REG_MT_COARSE_DELAYS_LT0_CH1_LSB) <= coarse_delays(0)(1);
  regs_read_arr(92)(REG_MT_COARSE_DELAYS_LT1_CH0_MSB downto REG_MT_COARSE_DELAYS_LT1_CH0_LSB) <= coarse_delays(1)(0);
  regs_read_arr(92)(REG_MT_COARSE_DELAYS_LT1_CH1_MSB downto REG_MT_COARSE_DELAYS_LT1_CH1_LSB) <= coarse_delays(1)(1);
  regs_read_arr(93)(REG_MT_COARSE_DELAYS_LT2_CH0_MSB downto REG_MT_COARSE_DELAYS_LT2_CH0_LSB) <= coarse_delays(2)(0);
  regs_read_arr(93)(REG_MT_COARSE_DELAYS_LT2_CH1_MSB downto REG_MT_COARSE_DELAYS_LT2_CH1_LSB) <= coarse_delays(2)(1);
  regs_read_arr(94)(REG_MT_COARSE_DELAYS_LT3_CH0_MSB downto REG_MT_COARSE_DELAYS_LT3_CH0_LSB) <= coarse_delays(3)(0);
  regs_read_arr(94)(REG_MT_COARSE_DELAYS_LT3_CH1_MSB downto REG_MT_COARSE_DELAYS_LT3_CH1_LSB) <= coarse_delays(3)(1);
  regs_read_arr(95)(REG_MT_COARSE_DELAYS_LT4_CH0_MSB downto REG_MT_COARSE_DELAYS_LT4_CH0_LSB) <= coarse_delays(4)(0);
  regs_read_arr(95)(REG_MT_COARSE_DELAYS_LT4_CH1_MSB downto REG_MT_COARSE_DELAYS_LT4_CH1_LSB) <= coarse_delays(4)(1);
  regs_read_arr(96)(REG_MT_COARSE_DELAYS_LT5_CH0_MSB downto REG_MT_COARSE_DELAYS_LT5_CH0_LSB) <= coarse_delays(5)(0);
  regs_read_arr(96)(REG_MT_COARSE_DELAYS_LT5_CH1_MSB downto REG_MT_COARSE_DELAYS_LT5_CH1_LSB) <= coarse_delays(5)(1);
  regs_read_arr(97)(REG_MT_COARSE_DELAYS_LT6_CH0_MSB downto REG_MT_COARSE_DELAYS_LT6_CH0_LSB) <= coarse_delays(6)(0);
  regs_read_arr(97)(REG_MT_COARSE_DELAYS_LT6_CH1_MSB downto REG_MT_COARSE_DELAYS_LT6_CH1_LSB) <= coarse_delays(6)(1);
  regs_read_arr(98)(REG_MT_COARSE_DELAYS_LT7_CH0_MSB downto REG_MT_COARSE_DELAYS_LT7_CH0_LSB) <= coarse_delays(7)(0);
  regs_read_arr(98)(REG_MT_COARSE_DELAYS_LT7_CH1_MSB downto REG_MT_COARSE_DELAYS_LT7_CH1_LSB) <= coarse_delays(7)(1);
  regs_read_arr(99)(REG_MT_COARSE_DELAYS_LT8_CH0_MSB downto REG_MT_COARSE_DELAYS_LT8_CH0_LSB) <= coarse_delays(8)(0);
  regs_read_arr(99)(REG_MT_COARSE_DELAYS_LT8_CH1_MSB downto REG_MT_COARSE_DELAYS_LT8_CH1_LSB) <= coarse_delays(8)(1);
  regs_read_arr(100)(REG_MT_COARSE_DELAYS_LT9_CH0_MSB downto REG_MT_COARSE_DELAYS_LT9_CH0_LSB) <= coarse_delays(9)(0);
  regs_read_arr(100)(REG_MT_COARSE_DELAYS_LT9_CH1_MSB downto REG_MT_COARSE_DELAYS_LT9_CH1_LSB) <= coarse_delays(9)(1);
  regs_read_arr(101)(REG_MT_COARSE_DELAYS_LT10_CH0_MSB downto REG_MT_COARSE_DELAYS_LT10_CH0_LSB) <= coarse_delays(10)(0);
  regs_read_arr(101)(REG_MT_COARSE_DELAYS_LT10_CH1_MSB downto REG_MT_COARSE_DELAYS_LT10_CH1_LSB) <= coarse_delays(10)(1);
  regs_read_arr(102)(REG_MT_COARSE_DELAYS_LT11_CH0_MSB downto REG_MT_COARSE_DELAYS_LT11_CH0_LSB) <= coarse_delays(11)(0);
  regs_read_arr(102)(REG_MT_COARSE_DELAYS_LT11_CH1_MSB downto REG_MT_COARSE_DELAYS_LT11_CH1_LSB) <= coarse_delays(11)(1);
  regs_read_arr(103)(REG_MT_COARSE_DELAYS_LT12_CH0_MSB downto REG_MT_COARSE_DELAYS_LT12_CH0_LSB) <= coarse_delays(12)(0);
  regs_read_arr(103)(REG_MT_COARSE_DELAYS_LT12_CH1_MSB downto REG_MT_COARSE_DELAYS_LT12_CH1_LSB) <= coarse_delays(12)(1);
  regs_read_arr(104)(REG_MT_COARSE_DELAYS_LT13_CH0_MSB downto REG_MT_COARSE_DELAYS_LT13_CH0_LSB) <= coarse_delays(13)(0);
  regs_read_arr(104)(REG_MT_COARSE_DELAYS_LT13_CH1_MSB downto REG_MT_COARSE_DELAYS_LT13_CH1_LSB) <= coarse_delays(13)(1);
  regs_read_arr(105)(REG_MT_COARSE_DELAYS_LT14_CH0_MSB downto REG_MT_COARSE_DELAYS_LT14_CH0_LSB) <= coarse_delays(14)(0);
  regs_read_arr(105)(REG_MT_COARSE_DELAYS_LT14_CH1_MSB downto REG_MT_COARSE_DELAYS_LT14_CH1_LSB) <= coarse_delays(14)(1);
  regs_read_arr(106)(REG_MT_COARSE_DELAYS_LT15_CH0_MSB downto REG_MT_COARSE_DELAYS_LT15_CH0_LSB) <= coarse_delays(15)(0);
  regs_read_arr(106)(REG_MT_COARSE_DELAYS_LT15_CH1_MSB downto REG_MT_COARSE_DELAYS_LT15_CH1_LSB) <= coarse_delays(15)(1);
  regs_read_arr(107)(REG_MT_COARSE_DELAYS_LT16_CH0_MSB downto REG_MT_COARSE_DELAYS_LT16_CH0_LSB) <= coarse_delays(16)(0);
  regs_read_arr(107)(REG_MT_COARSE_DELAYS_LT16_CH1_MSB downto REG_MT_COARSE_DELAYS_LT16_CH1_LSB) <= coarse_delays(16)(1);
  regs_read_arr(108)(REG_MT_COARSE_DELAYS_LT17_CH0_MSB downto REG_MT_COARSE_DELAYS_LT17_CH0_LSB) <= coarse_delays(17)(0);
  regs_read_arr(108)(REG_MT_COARSE_DELAYS_LT17_CH1_MSB downto REG_MT_COARSE_DELAYS_LT17_CH1_LSB) <= coarse_delays(17)(1);
  regs_read_arr(109)(REG_MT_COARSE_DELAYS_LT18_CH0_MSB downto REG_MT_COARSE_DELAYS_LT18_CH0_LSB) <= coarse_delays(18)(0);
  regs_read_arr(109)(REG_MT_COARSE_DELAYS_LT18_CH1_MSB downto REG_MT_COARSE_DELAYS_LT18_CH1_LSB) <= coarse_delays(18)(1);
  regs_read_arr(110)(REG_MT_COARSE_DELAYS_LT19_CH0_MSB downto REG_MT_COARSE_DELAYS_LT19_CH0_LSB) <= coarse_delays(19)(0);
  regs_read_arr(110)(REG_MT_COARSE_DELAYS_LT19_CH1_MSB downto REG_MT_COARSE_DELAYS_LT19_CH1_LSB) <= coarse_delays(19)(1);
  regs_read_arr(111)(REG_MT_POSNEGS_LT0_CH0_BIT) <= posnegs(0)(0);
  regs_read_arr(111)(REG_MT_POSNEGS_LT0_CH1_BIT) <= posnegs(0)(1);
  regs_read_arr(112)(REG_MT_POSNEGS_LT1_CH0_BIT) <= posnegs(1)(0);
  regs_read_arr(112)(REG_MT_POSNEGS_LT1_CH1_BIT) <= posnegs(1)(1);
  regs_read_arr(113)(REG_MT_POSNEGS_LT2_CH0_BIT) <= posnegs(2)(0);
  regs_read_arr(113)(REG_MT_POSNEGS_LT2_CH1_BIT) <= posnegs(2)(1);
  regs_read_arr(114)(REG_MT_POSNEGS_LT3_CH0_BIT) <= posnegs(3)(0);
  regs_read_arr(114)(REG_MT_POSNEGS_LT3_CH1_BIT) <= posnegs(3)(1);
  regs_read_arr(115)(REG_MT_POSNEGS_LT4_CH0_BIT) <= posnegs(4)(0);
  regs_read_arr(115)(REG_MT_POSNEGS_LT4_CH1_BIT) <= posnegs(4)(1);
  regs_read_arr(116)(REG_MT_POSNEGS_LT5_CH0_BIT) <= posnegs(5)(0);
  regs_read_arr(116)(REG_MT_POSNEGS_LT5_CH1_BIT) <= posnegs(5)(1);
  regs_read_arr(117)(REG_MT_POSNEGS_LT6_CH0_BIT) <= posnegs(6)(0);
  regs_read_arr(117)(REG_MT_POSNEGS_LT6_CH1_BIT) <= posnegs(6)(1);
  regs_read_arr(118)(REG_MT_POSNEGS_LT7_CH0_BIT) <= posnegs(7)(0);
  regs_read_arr(118)(REG_MT_POSNEGS_LT7_CH1_BIT) <= posnegs(7)(1);
  regs_read_arr(119)(REG_MT_POSNEGS_LT8_CH0_BIT) <= posnegs(8)(0);
  regs_read_arr(119)(REG_MT_POSNEGS_LT8_CH1_BIT) <= posnegs(8)(1);
  regs_read_arr(120)(REG_MT_POSNEGS_LT9_CH0_BIT) <= posnegs(9)(0);
  regs_read_arr(120)(REG_MT_POSNEGS_LT9_CH1_BIT) <= posnegs(9)(1);
  regs_read_arr(121)(REG_MT_POSNEGS_LT10_CH0_BIT) <= posnegs(10)(0);
  regs_read_arr(121)(REG_MT_POSNEGS_LT10_CH1_BIT) <= posnegs(10)(1);
  regs_read_arr(122)(REG_MT_POSNEGS_LT11_CH0_BIT) <= posnegs(11)(0);
  regs_read_arr(122)(REG_MT_POSNEGS_LT11_CH1_BIT) <= posnegs(11)(1);
  regs_read_arr(123)(REG_MT_POSNEGS_LT12_CH0_BIT) <= posnegs(12)(0);
  regs_read_arr(123)(REG_MT_POSNEGS_LT12_CH1_BIT) <= posnegs(12)(1);
  regs_read_arr(124)(REG_MT_POSNEGS_LT13_CH0_BIT) <= posnegs(13)(0);
  regs_read_arr(124)(REG_MT_POSNEGS_LT13_CH1_BIT) <= posnegs(13)(1);
  regs_read_arr(125)(REG_MT_POSNEGS_LT14_CH0_BIT) <= posnegs(14)(0);
  regs_read_arr(125)(REG_MT_POSNEGS_LT14_CH1_BIT) <= posnegs(14)(1);
  regs_read_arr(126)(REG_MT_POSNEGS_LT15_CH0_BIT) <= posnegs(15)(0);
  regs_read_arr(126)(REG_MT_POSNEGS_LT15_CH1_BIT) <= posnegs(15)(1);
  regs_read_arr(127)(REG_MT_POSNEGS_LT16_CH0_BIT) <= posnegs(16)(0);
  regs_read_arr(127)(REG_MT_POSNEGS_LT16_CH1_BIT) <= posnegs(16)(1);
  regs_read_arr(128)(REG_MT_POSNEGS_LT17_CH0_BIT) <= posnegs(17)(0);
  regs_read_arr(128)(REG_MT_POSNEGS_LT17_CH1_BIT) <= posnegs(17)(1);
  regs_read_arr(129)(REG_MT_POSNEGS_LT18_CH0_BIT) <= posnegs(18)(0);
  regs_read_arr(129)(REG_MT_POSNEGS_LT18_CH1_BIT) <= posnegs(18)(1);
  regs_read_arr(130)(REG_MT_POSNEGS_LT19_CH0_BIT) <= posnegs(19)(0);
  regs_read_arr(130)(REG_MT_POSNEGS_LT19_CH1_BIT) <= posnegs(19)(1);
  regs_read_arr(131)(REG_MT_XADC_CALIBRATION_MSB downto REG_MT_XADC_CALIBRATION_LSB) <= calibration;
  regs_read_arr(131)(REG_MT_XADC_VCCPINT_MSB downto REG_MT_XADC_VCCPINT_LSB) <= vccpint;
  regs_read_arr(132)(REG_MT_XADC_VCCPAUX_MSB downto REG_MT_XADC_VCCPAUX_LSB) <= vccpaux;
  regs_read_arr(132)(REG_MT_XADC_VCCODDR_MSB downto REG_MT_XADC_VCCODDR_LSB) <= vccoddr;
  regs_read_arr(133)(REG_MT_XADC_TEMP_MSB downto REG_MT_XADC_TEMP_LSB) <= temp;
  regs_read_arr(133)(REG_MT_XADC_VCCINT_MSB downto REG_MT_XADC_VCCINT_LSB) <= vccint;
  regs_read_arr(134)(REG_MT_XADC_VCCAUX_MSB downto REG_MT_XADC_VCCAUX_LSB) <= vccaux;
  regs_read_arr(134)(REG_MT_XADC_VCCBRAM_MSB downto REG_MT_XADC_VCCBRAM_LSB) <= vccbram;
  regs_read_arr(135)(REG_MT_HOG_GLOBAL_DATE_MSB downto REG_MT_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
  regs_read_arr(136)(REG_MT_HOG_GLOBAL_TIME_MSB downto REG_MT_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
  regs_read_arr(137)(REG_MT_HOG_GLOBAL_VER_MSB downto REG_MT_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
  regs_read_arr(138)(REG_MT_HOG_GLOBAL_SHA_MSB downto REG_MT_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
  regs_read_arr(139)(REG_MT_HOG_TOP_SHA_MSB downto REG_MT_HOG_TOP_SHA_LSB) <= TOP_SHA;
  regs_read_arr(140)(REG_MT_HOG_TOP_VER_MSB downto REG_MT_HOG_TOP_VER_LSB) <= TOP_VER;
  regs_read_arr(141)(REG_MT_HOG_HOG_SHA_MSB downto REG_MT_HOG_HOG_SHA_LSB) <= HOG_SHA;
  regs_read_arr(142)(REG_MT_HOG_HOG_VER_MSB downto REG_MT_HOG_HOG_VER_LSB) <= HOG_VER;

  -- Connect write signals
  loopback <= regs_write_arr(0)(REG_MT_LOOPBACK_MSB downto REG_MT_LOOPBACK_LSB);
  dsi_on_ipb <= regs_write_arr(7)(REG_MT_DSI_ON_MSB downto REG_MT_DSI_ON_LSB);
  trig_gen_rate <= regs_write_arr(9)(REG_MT_TRIG_GEN_RATE_MSB downto REG_MT_TRIG_GEN_RATE_LSB);
  pulse_stretch <= regs_write_arr(10)(REG_MT_PULSE_STRETCH_MSB downto REG_MT_PULSE_STRETCH_LSB);
  hit_mask(0) <= regs_write_arr(51)(REG_MT_HIT_MASK_LT0_MSB downto REG_MT_HIT_MASK_LT0_LSB);
  hit_mask(1) <= regs_write_arr(52)(REG_MT_HIT_MASK_LT1_MSB downto REG_MT_HIT_MASK_LT1_LSB);
  hit_mask(2) <= regs_write_arr(53)(REG_MT_HIT_MASK_LT2_MSB downto REG_MT_HIT_MASK_LT2_LSB);
  hit_mask(3) <= regs_write_arr(54)(REG_MT_HIT_MASK_LT3_MSB downto REG_MT_HIT_MASK_LT3_LSB);
  hit_mask(4) <= regs_write_arr(55)(REG_MT_HIT_MASK_LT4_MSB downto REG_MT_HIT_MASK_LT4_LSB);
  hit_mask(5) <= regs_write_arr(56)(REG_MT_HIT_MASK_LT5_MSB downto REG_MT_HIT_MASK_LT5_LSB);
  hit_mask(6) <= regs_write_arr(57)(REG_MT_HIT_MASK_LT6_MSB downto REG_MT_HIT_MASK_LT6_LSB);
  hit_mask(7) <= regs_write_arr(58)(REG_MT_HIT_MASK_LT7_MSB downto REG_MT_HIT_MASK_LT7_LSB);
  hit_mask(8) <= regs_write_arr(59)(REG_MT_HIT_MASK_LT8_MSB downto REG_MT_HIT_MASK_LT8_LSB);
  hit_mask(9) <= regs_write_arr(60)(REG_MT_HIT_MASK_LT9_MSB downto REG_MT_HIT_MASK_LT9_LSB);
  hit_mask(10) <= regs_write_arr(61)(REG_MT_HIT_MASK_LT10_MSB downto REG_MT_HIT_MASK_LT10_LSB);
  hit_mask(11) <= regs_write_arr(62)(REG_MT_HIT_MASK_LT11_MSB downto REG_MT_HIT_MASK_LT11_LSB);
  hit_mask(12) <= regs_write_arr(63)(REG_MT_HIT_MASK_LT12_MSB downto REG_MT_HIT_MASK_LT12_LSB);
  hit_mask(13) <= regs_write_arr(64)(REG_MT_HIT_MASK_LT13_MSB downto REG_MT_HIT_MASK_LT13_LSB);
  hit_mask(14) <= regs_write_arr(65)(REG_MT_HIT_MASK_LT14_MSB downto REG_MT_HIT_MASK_LT14_LSB);
  hit_mask(15) <= regs_write_arr(66)(REG_MT_HIT_MASK_LT15_MSB downto REG_MT_HIT_MASK_LT15_LSB);
  hit_mask(16) <= regs_write_arr(67)(REG_MT_HIT_MASK_LT16_MSB downto REG_MT_HIT_MASK_LT16_LSB);
  hit_mask(17) <= regs_write_arr(68)(REG_MT_HIT_MASK_LT17_MSB downto REG_MT_HIT_MASK_LT17_LSB);
  hit_mask(18) <= regs_write_arr(69)(REG_MT_HIT_MASK_LT18_MSB downto REG_MT_HIT_MASK_LT18_LSB);
  hit_mask(19) <= regs_write_arr(70)(REG_MT_HIT_MASK_LT19_MSB downto REG_MT_HIT_MASK_LT19_LSB);
  fine_delays(0)(0) <= regs_write_arr(71)(REG_MT_FINE_DELAYS_LT0_CH0_MSB downto REG_MT_FINE_DELAYS_LT0_CH0_LSB);
  fine_delays(0)(1) <= regs_write_arr(71)(REG_MT_FINE_DELAYS_LT0_CH1_MSB downto REG_MT_FINE_DELAYS_LT0_CH1_LSB);
  fine_delays(1)(0) <= regs_write_arr(72)(REG_MT_FINE_DELAYS_LT1_CH0_MSB downto REG_MT_FINE_DELAYS_LT1_CH0_LSB);
  fine_delays(1)(1) <= regs_write_arr(72)(REG_MT_FINE_DELAYS_LT1_CH1_MSB downto REG_MT_FINE_DELAYS_LT1_CH1_LSB);
  fine_delays(2)(0) <= regs_write_arr(73)(REG_MT_FINE_DELAYS_LT2_CH0_MSB downto REG_MT_FINE_DELAYS_LT2_CH0_LSB);
  fine_delays(2)(1) <= regs_write_arr(73)(REG_MT_FINE_DELAYS_LT2_CH1_MSB downto REG_MT_FINE_DELAYS_LT2_CH1_LSB);
  fine_delays(3)(0) <= regs_write_arr(74)(REG_MT_FINE_DELAYS_LT3_CH0_MSB downto REG_MT_FINE_DELAYS_LT3_CH0_LSB);
  fine_delays(3)(1) <= regs_write_arr(74)(REG_MT_FINE_DELAYS_LT3_CH1_MSB downto REG_MT_FINE_DELAYS_LT3_CH1_LSB);
  fine_delays(4)(0) <= regs_write_arr(75)(REG_MT_FINE_DELAYS_LT4_CH0_MSB downto REG_MT_FINE_DELAYS_LT4_CH0_LSB);
  fine_delays(4)(1) <= regs_write_arr(75)(REG_MT_FINE_DELAYS_LT4_CH1_MSB downto REG_MT_FINE_DELAYS_LT4_CH1_LSB);
  fine_delays(5)(0) <= regs_write_arr(76)(REG_MT_FINE_DELAYS_LT5_CH0_MSB downto REG_MT_FINE_DELAYS_LT5_CH0_LSB);
  fine_delays(5)(1) <= regs_write_arr(76)(REG_MT_FINE_DELAYS_LT5_CH1_MSB downto REG_MT_FINE_DELAYS_LT5_CH1_LSB);
  fine_delays(6)(0) <= regs_write_arr(77)(REG_MT_FINE_DELAYS_LT6_CH0_MSB downto REG_MT_FINE_DELAYS_LT6_CH0_LSB);
  fine_delays(6)(1) <= regs_write_arr(77)(REG_MT_FINE_DELAYS_LT6_CH1_MSB downto REG_MT_FINE_DELAYS_LT6_CH1_LSB);
  fine_delays(7)(0) <= regs_write_arr(78)(REG_MT_FINE_DELAYS_LT7_CH0_MSB downto REG_MT_FINE_DELAYS_LT7_CH0_LSB);
  fine_delays(7)(1) <= regs_write_arr(78)(REG_MT_FINE_DELAYS_LT7_CH1_MSB downto REG_MT_FINE_DELAYS_LT7_CH1_LSB);
  fine_delays(8)(0) <= regs_write_arr(79)(REG_MT_FINE_DELAYS_LT8_CH0_MSB downto REG_MT_FINE_DELAYS_LT8_CH0_LSB);
  fine_delays(8)(1) <= regs_write_arr(79)(REG_MT_FINE_DELAYS_LT8_CH1_MSB downto REG_MT_FINE_DELAYS_LT8_CH1_LSB);
  fine_delays(9)(0) <= regs_write_arr(80)(REG_MT_FINE_DELAYS_LT9_CH0_MSB downto REG_MT_FINE_DELAYS_LT9_CH0_LSB);
  fine_delays(9)(1) <= regs_write_arr(80)(REG_MT_FINE_DELAYS_LT9_CH1_MSB downto REG_MT_FINE_DELAYS_LT9_CH1_LSB);
  fine_delays(10)(0) <= regs_write_arr(81)(REG_MT_FINE_DELAYS_LT10_CH0_MSB downto REG_MT_FINE_DELAYS_LT10_CH0_LSB);
  fine_delays(10)(1) <= regs_write_arr(81)(REG_MT_FINE_DELAYS_LT10_CH1_MSB downto REG_MT_FINE_DELAYS_LT10_CH1_LSB);
  fine_delays(11)(0) <= regs_write_arr(82)(REG_MT_FINE_DELAYS_LT11_CH0_MSB downto REG_MT_FINE_DELAYS_LT11_CH0_LSB);
  fine_delays(11)(1) <= regs_write_arr(82)(REG_MT_FINE_DELAYS_LT11_CH1_MSB downto REG_MT_FINE_DELAYS_LT11_CH1_LSB);
  fine_delays(12)(0) <= regs_write_arr(83)(REG_MT_FINE_DELAYS_LT12_CH0_MSB downto REG_MT_FINE_DELAYS_LT12_CH0_LSB);
  fine_delays(12)(1) <= regs_write_arr(83)(REG_MT_FINE_DELAYS_LT12_CH1_MSB downto REG_MT_FINE_DELAYS_LT12_CH1_LSB);
  fine_delays(13)(0) <= regs_write_arr(84)(REG_MT_FINE_DELAYS_LT13_CH0_MSB downto REG_MT_FINE_DELAYS_LT13_CH0_LSB);
  fine_delays(13)(1) <= regs_write_arr(84)(REG_MT_FINE_DELAYS_LT13_CH1_MSB downto REG_MT_FINE_DELAYS_LT13_CH1_LSB);
  fine_delays(14)(0) <= regs_write_arr(85)(REG_MT_FINE_DELAYS_LT14_CH0_MSB downto REG_MT_FINE_DELAYS_LT14_CH0_LSB);
  fine_delays(14)(1) <= regs_write_arr(85)(REG_MT_FINE_DELAYS_LT14_CH1_MSB downto REG_MT_FINE_DELAYS_LT14_CH1_LSB);
  fine_delays(15)(0) <= regs_write_arr(86)(REG_MT_FINE_DELAYS_LT15_CH0_MSB downto REG_MT_FINE_DELAYS_LT15_CH0_LSB);
  fine_delays(15)(1) <= regs_write_arr(86)(REG_MT_FINE_DELAYS_LT15_CH1_MSB downto REG_MT_FINE_DELAYS_LT15_CH1_LSB);
  fine_delays(16)(0) <= regs_write_arr(87)(REG_MT_FINE_DELAYS_LT16_CH0_MSB downto REG_MT_FINE_DELAYS_LT16_CH0_LSB);
  fine_delays(16)(1) <= regs_write_arr(87)(REG_MT_FINE_DELAYS_LT16_CH1_MSB downto REG_MT_FINE_DELAYS_LT16_CH1_LSB);
  fine_delays(17)(0) <= regs_write_arr(88)(REG_MT_FINE_DELAYS_LT17_CH0_MSB downto REG_MT_FINE_DELAYS_LT17_CH0_LSB);
  fine_delays(17)(1) <= regs_write_arr(88)(REG_MT_FINE_DELAYS_LT17_CH1_MSB downto REG_MT_FINE_DELAYS_LT17_CH1_LSB);
  fine_delays(18)(0) <= regs_write_arr(89)(REG_MT_FINE_DELAYS_LT18_CH0_MSB downto REG_MT_FINE_DELAYS_LT18_CH0_LSB);
  fine_delays(18)(1) <= regs_write_arr(89)(REG_MT_FINE_DELAYS_LT18_CH1_MSB downto REG_MT_FINE_DELAYS_LT18_CH1_LSB);
  fine_delays(19)(0) <= regs_write_arr(90)(REG_MT_FINE_DELAYS_LT19_CH0_MSB downto REG_MT_FINE_DELAYS_LT19_CH0_LSB);
  fine_delays(19)(1) <= regs_write_arr(90)(REG_MT_FINE_DELAYS_LT19_CH1_MSB downto REG_MT_FINE_DELAYS_LT19_CH1_LSB);
  coarse_delays(0)(0) <= regs_write_arr(91)(REG_MT_COARSE_DELAYS_LT0_CH0_MSB downto REG_MT_COARSE_DELAYS_LT0_CH0_LSB);
  coarse_delays(0)(1) <= regs_write_arr(91)(REG_MT_COARSE_DELAYS_LT0_CH1_MSB downto REG_MT_COARSE_DELAYS_LT0_CH1_LSB);
  coarse_delays(1)(0) <= regs_write_arr(92)(REG_MT_COARSE_DELAYS_LT1_CH0_MSB downto REG_MT_COARSE_DELAYS_LT1_CH0_LSB);
  coarse_delays(1)(1) <= regs_write_arr(92)(REG_MT_COARSE_DELAYS_LT1_CH1_MSB downto REG_MT_COARSE_DELAYS_LT1_CH1_LSB);
  coarse_delays(2)(0) <= regs_write_arr(93)(REG_MT_COARSE_DELAYS_LT2_CH0_MSB downto REG_MT_COARSE_DELAYS_LT2_CH0_LSB);
  coarse_delays(2)(1) <= regs_write_arr(93)(REG_MT_COARSE_DELAYS_LT2_CH1_MSB downto REG_MT_COARSE_DELAYS_LT2_CH1_LSB);
  coarse_delays(3)(0) <= regs_write_arr(94)(REG_MT_COARSE_DELAYS_LT3_CH0_MSB downto REG_MT_COARSE_DELAYS_LT3_CH0_LSB);
  coarse_delays(3)(1) <= regs_write_arr(94)(REG_MT_COARSE_DELAYS_LT3_CH1_MSB downto REG_MT_COARSE_DELAYS_LT3_CH1_LSB);
  coarse_delays(4)(0) <= regs_write_arr(95)(REG_MT_COARSE_DELAYS_LT4_CH0_MSB downto REG_MT_COARSE_DELAYS_LT4_CH0_LSB);
  coarse_delays(4)(1) <= regs_write_arr(95)(REG_MT_COARSE_DELAYS_LT4_CH1_MSB downto REG_MT_COARSE_DELAYS_LT4_CH1_LSB);
  coarse_delays(5)(0) <= regs_write_arr(96)(REG_MT_COARSE_DELAYS_LT5_CH0_MSB downto REG_MT_COARSE_DELAYS_LT5_CH0_LSB);
  coarse_delays(5)(1) <= regs_write_arr(96)(REG_MT_COARSE_DELAYS_LT5_CH1_MSB downto REG_MT_COARSE_DELAYS_LT5_CH1_LSB);
  coarse_delays(6)(0) <= regs_write_arr(97)(REG_MT_COARSE_DELAYS_LT6_CH0_MSB downto REG_MT_COARSE_DELAYS_LT6_CH0_LSB);
  coarse_delays(6)(1) <= regs_write_arr(97)(REG_MT_COARSE_DELAYS_LT6_CH1_MSB downto REG_MT_COARSE_DELAYS_LT6_CH1_LSB);
  coarse_delays(7)(0) <= regs_write_arr(98)(REG_MT_COARSE_DELAYS_LT7_CH0_MSB downto REG_MT_COARSE_DELAYS_LT7_CH0_LSB);
  coarse_delays(7)(1) <= regs_write_arr(98)(REG_MT_COARSE_DELAYS_LT7_CH1_MSB downto REG_MT_COARSE_DELAYS_LT7_CH1_LSB);
  coarse_delays(8)(0) <= regs_write_arr(99)(REG_MT_COARSE_DELAYS_LT8_CH0_MSB downto REG_MT_COARSE_DELAYS_LT8_CH0_LSB);
  coarse_delays(8)(1) <= regs_write_arr(99)(REG_MT_COARSE_DELAYS_LT8_CH1_MSB downto REG_MT_COARSE_DELAYS_LT8_CH1_LSB);
  coarse_delays(9)(0) <= regs_write_arr(100)(REG_MT_COARSE_DELAYS_LT9_CH0_MSB downto REG_MT_COARSE_DELAYS_LT9_CH0_LSB);
  coarse_delays(9)(1) <= regs_write_arr(100)(REG_MT_COARSE_DELAYS_LT9_CH1_MSB downto REG_MT_COARSE_DELAYS_LT9_CH1_LSB);
  coarse_delays(10)(0) <= regs_write_arr(101)(REG_MT_COARSE_DELAYS_LT10_CH0_MSB downto REG_MT_COARSE_DELAYS_LT10_CH0_LSB);
  coarse_delays(10)(1) <= regs_write_arr(101)(REG_MT_COARSE_DELAYS_LT10_CH1_MSB downto REG_MT_COARSE_DELAYS_LT10_CH1_LSB);
  coarse_delays(11)(0) <= regs_write_arr(102)(REG_MT_COARSE_DELAYS_LT11_CH0_MSB downto REG_MT_COARSE_DELAYS_LT11_CH0_LSB);
  coarse_delays(11)(1) <= regs_write_arr(102)(REG_MT_COARSE_DELAYS_LT11_CH1_MSB downto REG_MT_COARSE_DELAYS_LT11_CH1_LSB);
  coarse_delays(12)(0) <= regs_write_arr(103)(REG_MT_COARSE_DELAYS_LT12_CH0_MSB downto REG_MT_COARSE_DELAYS_LT12_CH0_LSB);
  coarse_delays(12)(1) <= regs_write_arr(103)(REG_MT_COARSE_DELAYS_LT12_CH1_MSB downto REG_MT_COARSE_DELAYS_LT12_CH1_LSB);
  coarse_delays(13)(0) <= regs_write_arr(104)(REG_MT_COARSE_DELAYS_LT13_CH0_MSB downto REG_MT_COARSE_DELAYS_LT13_CH0_LSB);
  coarse_delays(13)(1) <= regs_write_arr(104)(REG_MT_COARSE_DELAYS_LT13_CH1_MSB downto REG_MT_COARSE_DELAYS_LT13_CH1_LSB);
  coarse_delays(14)(0) <= regs_write_arr(105)(REG_MT_COARSE_DELAYS_LT14_CH0_MSB downto REG_MT_COARSE_DELAYS_LT14_CH0_LSB);
  coarse_delays(14)(1) <= regs_write_arr(105)(REG_MT_COARSE_DELAYS_LT14_CH1_MSB downto REG_MT_COARSE_DELAYS_LT14_CH1_LSB);
  coarse_delays(15)(0) <= regs_write_arr(106)(REG_MT_COARSE_DELAYS_LT15_CH0_MSB downto REG_MT_COARSE_DELAYS_LT15_CH0_LSB);
  coarse_delays(15)(1) <= regs_write_arr(106)(REG_MT_COARSE_DELAYS_LT15_CH1_MSB downto REG_MT_COARSE_DELAYS_LT15_CH1_LSB);
  coarse_delays(16)(0) <= regs_write_arr(107)(REG_MT_COARSE_DELAYS_LT16_CH0_MSB downto REG_MT_COARSE_DELAYS_LT16_CH0_LSB);
  coarse_delays(16)(1) <= regs_write_arr(107)(REG_MT_COARSE_DELAYS_LT16_CH1_MSB downto REG_MT_COARSE_DELAYS_LT16_CH1_LSB);
  coarse_delays(17)(0) <= regs_write_arr(108)(REG_MT_COARSE_DELAYS_LT17_CH0_MSB downto REG_MT_COARSE_DELAYS_LT17_CH0_LSB);
  coarse_delays(17)(1) <= regs_write_arr(108)(REG_MT_COARSE_DELAYS_LT17_CH1_MSB downto REG_MT_COARSE_DELAYS_LT17_CH1_LSB);
  coarse_delays(18)(0) <= regs_write_arr(109)(REG_MT_COARSE_DELAYS_LT18_CH0_MSB downto REG_MT_COARSE_DELAYS_LT18_CH0_LSB);
  coarse_delays(18)(1) <= regs_write_arr(109)(REG_MT_COARSE_DELAYS_LT18_CH1_MSB downto REG_MT_COARSE_DELAYS_LT18_CH1_LSB);
  coarse_delays(19)(0) <= regs_write_arr(110)(REG_MT_COARSE_DELAYS_LT19_CH0_MSB downto REG_MT_COARSE_DELAYS_LT19_CH0_LSB);
  coarse_delays(19)(1) <= regs_write_arr(110)(REG_MT_COARSE_DELAYS_LT19_CH1_MSB downto REG_MT_COARSE_DELAYS_LT19_CH1_LSB);
  posnegs(0)(0) <= regs_write_arr(111)(REG_MT_POSNEGS_LT0_CH0_BIT);
  posnegs(0)(1) <= regs_write_arr(111)(REG_MT_POSNEGS_LT0_CH1_BIT);
  posnegs(1)(0) <= regs_write_arr(112)(REG_MT_POSNEGS_LT1_CH0_BIT);
  posnegs(1)(1) <= regs_write_arr(112)(REG_MT_POSNEGS_LT1_CH1_BIT);
  posnegs(2)(0) <= regs_write_arr(113)(REG_MT_POSNEGS_LT2_CH0_BIT);
  posnegs(2)(1) <= regs_write_arr(113)(REG_MT_POSNEGS_LT2_CH1_BIT);
  posnegs(3)(0) <= regs_write_arr(114)(REG_MT_POSNEGS_LT3_CH0_BIT);
  posnegs(3)(1) <= regs_write_arr(114)(REG_MT_POSNEGS_LT3_CH1_BIT);
  posnegs(4)(0) <= regs_write_arr(115)(REG_MT_POSNEGS_LT4_CH0_BIT);
  posnegs(4)(1) <= regs_write_arr(115)(REG_MT_POSNEGS_LT4_CH1_BIT);
  posnegs(5)(0) <= regs_write_arr(116)(REG_MT_POSNEGS_LT5_CH0_BIT);
  posnegs(5)(1) <= regs_write_arr(116)(REG_MT_POSNEGS_LT5_CH1_BIT);
  posnegs(6)(0) <= regs_write_arr(117)(REG_MT_POSNEGS_LT6_CH0_BIT);
  posnegs(6)(1) <= regs_write_arr(117)(REG_MT_POSNEGS_LT6_CH1_BIT);
  posnegs(7)(0) <= regs_write_arr(118)(REG_MT_POSNEGS_LT7_CH0_BIT);
  posnegs(7)(1) <= regs_write_arr(118)(REG_MT_POSNEGS_LT7_CH1_BIT);
  posnegs(8)(0) <= regs_write_arr(119)(REG_MT_POSNEGS_LT8_CH0_BIT);
  posnegs(8)(1) <= regs_write_arr(119)(REG_MT_POSNEGS_LT8_CH1_BIT);
  posnegs(9)(0) <= regs_write_arr(120)(REG_MT_POSNEGS_LT9_CH0_BIT);
  posnegs(9)(1) <= regs_write_arr(120)(REG_MT_POSNEGS_LT9_CH1_BIT);
  posnegs(10)(0) <= regs_write_arr(121)(REG_MT_POSNEGS_LT10_CH0_BIT);
  posnegs(10)(1) <= regs_write_arr(121)(REG_MT_POSNEGS_LT10_CH1_BIT);
  posnegs(11)(0) <= regs_write_arr(122)(REG_MT_POSNEGS_LT11_CH0_BIT);
  posnegs(11)(1) <= regs_write_arr(122)(REG_MT_POSNEGS_LT11_CH1_BIT);
  posnegs(12)(0) <= regs_write_arr(123)(REG_MT_POSNEGS_LT12_CH0_BIT);
  posnegs(12)(1) <= regs_write_arr(123)(REG_MT_POSNEGS_LT12_CH1_BIT);
  posnegs(13)(0) <= regs_write_arr(124)(REG_MT_POSNEGS_LT13_CH0_BIT);
  posnegs(13)(1) <= regs_write_arr(124)(REG_MT_POSNEGS_LT13_CH1_BIT);
  posnegs(14)(0) <= regs_write_arr(125)(REG_MT_POSNEGS_LT14_CH0_BIT);
  posnegs(14)(1) <= regs_write_arr(125)(REG_MT_POSNEGS_LT14_CH1_BIT);
  posnegs(15)(0) <= regs_write_arr(126)(REG_MT_POSNEGS_LT15_CH0_BIT);
  posnegs(15)(1) <= regs_write_arr(126)(REG_MT_POSNEGS_LT15_CH1_BIT);
  posnegs(16)(0) <= regs_write_arr(127)(REG_MT_POSNEGS_LT16_CH0_BIT);
  posnegs(16)(1) <= regs_write_arr(127)(REG_MT_POSNEGS_LT16_CH1_BIT);
  posnegs(17)(0) <= regs_write_arr(128)(REG_MT_POSNEGS_LT17_CH0_BIT);
  posnegs(17)(1) <= regs_write_arr(128)(REG_MT_POSNEGS_LT17_CH1_BIT);
  posnegs(18)(0) <= regs_write_arr(129)(REG_MT_POSNEGS_LT18_CH0_BIT);
  posnegs(18)(1) <= regs_write_arr(129)(REG_MT_POSNEGS_LT18_CH1_BIT);
  posnegs(19)(0) <= regs_write_arr(130)(REG_MT_POSNEGS_LT19_CH0_BIT);
  posnegs(19)(1) <= regs_write_arr(130)(REG_MT_POSNEGS_LT19_CH1_BIT);

  -- Connect write pulse signals
  trigger_ipb <= regs_write_pulse_arr(8);

  -- Connect write done signals

  -- Connect read pulse signals

  -- Connect counter instances

  COUNTER_MT_HIT_COUNTERS_RB0 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(0)),
      snap_i    => '1',
      count_o   => hit_count_0
  );


  COUNTER_MT_HIT_COUNTERS_RB1 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(1)),
      snap_i    => '1',
      count_o   => hit_count_1
  );


  COUNTER_MT_HIT_COUNTERS_RB2 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(2)),
      snap_i    => '1',
      count_o   => hit_count_2
  );


  COUNTER_MT_HIT_COUNTERS_RB3 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(3)),
      snap_i    => '1',
      count_o   => hit_count_3
  );


  COUNTER_MT_HIT_COUNTERS_RB4 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(4)),
      snap_i    => '1',
      count_o   => hit_count_4
  );


  COUNTER_MT_HIT_COUNTERS_RB5 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(5)),
      snap_i    => '1',
      count_o   => hit_count_5
  );


  COUNTER_MT_HIT_COUNTERS_RB6 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(6)),
      snap_i    => '1',
      count_o   => hit_count_6
  );


  COUNTER_MT_HIT_COUNTERS_RB7 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(7)),
      snap_i    => '1',
      count_o   => hit_count_7
  );


  COUNTER_MT_HIT_COUNTERS_RB8 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(8)),
      snap_i    => '1',
      count_o   => hit_count_8
  );


  COUNTER_MT_HIT_COUNTERS_RB9 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(9)),
      snap_i    => '1',
      count_o   => hit_count_9
  );


  COUNTER_MT_HIT_COUNTERS_RB10 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(10)),
      snap_i    => '1',
      count_o   => hit_count_10
  );


  COUNTER_MT_HIT_COUNTERS_RB11 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(11)),
      snap_i    => '1',
      count_o   => hit_count_11
  );


  COUNTER_MT_HIT_COUNTERS_RB12 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(12)),
      snap_i    => '1',
      count_o   => hit_count_12
  );


  COUNTER_MT_HIT_COUNTERS_RB13 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(13)),
      snap_i    => '1',
      count_o   => hit_count_13
  );


  COUNTER_MT_HIT_COUNTERS_RB14 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(14)),
      snap_i    => '1',
      count_o   => hit_count_14
  );


  COUNTER_MT_HIT_COUNTERS_RB15 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(15)),
      snap_i    => '1',
      count_o   => hit_count_15
  );


  COUNTER_MT_HIT_COUNTERS_RB16 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(16)),
      snap_i    => '1',
      count_o   => hit_count_16
  );


  COUNTER_MT_HIT_COUNTERS_RB17 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(17)),
      snap_i    => '1',
      count_o   => hit_count_17
  );


  COUNTER_MT_HIT_COUNTERS_RB18 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(18)),
      snap_i    => '1',
      count_o   => hit_count_18
  );


  COUNTER_MT_HIT_COUNTERS_RB19 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(19)),
      snap_i    => '1',
      count_o   => hit_count_19
  );


  COUNTER_MT_HIT_COUNTERS_RB20 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(20)),
      snap_i    => '1',
      count_o   => hit_count_20
  );


  COUNTER_MT_HIT_COUNTERS_RB21 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(21)),
      snap_i    => '1',
      count_o   => hit_count_21
  );


  COUNTER_MT_HIT_COUNTERS_RB22 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(22)),
      snap_i    => '1',
      count_o   => hit_count_22
  );


  COUNTER_MT_HIT_COUNTERS_RB23 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(23)),
      snap_i    => '1',
      count_o   => hit_count_23
  );


  COUNTER_MT_HIT_COUNTERS_RB24 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(24)),
      snap_i    => '1',
      count_o   => hit_count_24
  );


  COUNTER_MT_HIT_COUNTERS_RB25 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(25)),
      snap_i    => '1',
      count_o   => hit_count_25
  );


  COUNTER_MT_HIT_COUNTERS_RB26 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(26)),
      snap_i    => '1',
      count_o   => hit_count_26
  );


  COUNTER_MT_HIT_COUNTERS_RB27 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(27)),
      snap_i    => '1',
      count_o   => hit_count_27
  );


  COUNTER_MT_HIT_COUNTERS_RB28 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(28)),
      snap_i    => '1',
      count_o   => hit_count_28
  );


  COUNTER_MT_HIT_COUNTERS_RB29 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(29)),
      snap_i    => '1',
      count_o   => hit_count_29
  );


  COUNTER_MT_HIT_COUNTERS_RB30 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(30)),
      snap_i    => '1',
      count_o   => hit_count_30
  );


  COUNTER_MT_HIT_COUNTERS_RB31 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(31)),
      snap_i    => '1',
      count_o   => hit_count_31
  );


  COUNTER_MT_HIT_COUNTERS_RB32 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(32)),
      snap_i    => '1',
      count_o   => hit_count_32
  );


  COUNTER_MT_HIT_COUNTERS_RB33 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(33)),
      snap_i    => '1',
      count_o   => hit_count_33
  );


  COUNTER_MT_HIT_COUNTERS_RB34 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(34)),
      snap_i    => '1',
      count_o   => hit_count_34
  );


  COUNTER_MT_HIT_COUNTERS_RB35 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(35)),
      snap_i    => '1',
      count_o   => hit_count_35
  );


  COUNTER_MT_HIT_COUNTERS_RB36 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(36)),
      snap_i    => '1',
      count_o   => hit_count_36
  );


  COUNTER_MT_HIT_COUNTERS_RB37 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(37)),
      snap_i    => '1',
      count_o   => hit_count_37
  );


  COUNTER_MT_HIT_COUNTERS_RB38 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(38)),
      snap_i    => '1',
      count_o   => hit_count_38
  );


  COUNTER_MT_HIT_COUNTERS_RB39 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => or_reduce(rb_hits(39)),
      snap_i    => '1',
      count_o   => hit_count_39
  );


  -- Connect rate instances

  -- Connect read ready signals

  -- Defaults
  regs_defaults(0)(REG_MT_LOOPBACK_MSB downto REG_MT_LOOPBACK_LSB) <= REG_MT_LOOPBACK_DEFAULT;
  regs_defaults(7)(REG_MT_DSI_ON_MSB downto REG_MT_DSI_ON_LSB) <= REG_MT_DSI_ON_DEFAULT;
  regs_defaults(9)(REG_MT_TRIG_GEN_RATE_MSB downto REG_MT_TRIG_GEN_RATE_LSB) <= REG_MT_TRIG_GEN_RATE_DEFAULT;
  regs_defaults(10)(REG_MT_PULSE_STRETCH_MSB downto REG_MT_PULSE_STRETCH_LSB) <= REG_MT_PULSE_STRETCH_DEFAULT;
  regs_defaults(51)(REG_MT_HIT_MASK_LT0_MSB downto REG_MT_HIT_MASK_LT0_LSB) <= REG_MT_HIT_MASK_LT0_DEFAULT;
  regs_defaults(52)(REG_MT_HIT_MASK_LT1_MSB downto REG_MT_HIT_MASK_LT1_LSB) <= REG_MT_HIT_MASK_LT1_DEFAULT;
  regs_defaults(53)(REG_MT_HIT_MASK_LT2_MSB downto REG_MT_HIT_MASK_LT2_LSB) <= REG_MT_HIT_MASK_LT2_DEFAULT;
  regs_defaults(54)(REG_MT_HIT_MASK_LT3_MSB downto REG_MT_HIT_MASK_LT3_LSB) <= REG_MT_HIT_MASK_LT3_DEFAULT;
  regs_defaults(55)(REG_MT_HIT_MASK_LT4_MSB downto REG_MT_HIT_MASK_LT4_LSB) <= REG_MT_HIT_MASK_LT4_DEFAULT;
  regs_defaults(56)(REG_MT_HIT_MASK_LT5_MSB downto REG_MT_HIT_MASK_LT5_LSB) <= REG_MT_HIT_MASK_LT5_DEFAULT;
  regs_defaults(57)(REG_MT_HIT_MASK_LT6_MSB downto REG_MT_HIT_MASK_LT6_LSB) <= REG_MT_HIT_MASK_LT6_DEFAULT;
  regs_defaults(58)(REG_MT_HIT_MASK_LT7_MSB downto REG_MT_HIT_MASK_LT7_LSB) <= REG_MT_HIT_MASK_LT7_DEFAULT;
  regs_defaults(59)(REG_MT_HIT_MASK_LT8_MSB downto REG_MT_HIT_MASK_LT8_LSB) <= REG_MT_HIT_MASK_LT8_DEFAULT;
  regs_defaults(60)(REG_MT_HIT_MASK_LT9_MSB downto REG_MT_HIT_MASK_LT9_LSB) <= REG_MT_HIT_MASK_LT9_DEFAULT;
  regs_defaults(61)(REG_MT_HIT_MASK_LT10_MSB downto REG_MT_HIT_MASK_LT10_LSB) <= REG_MT_HIT_MASK_LT10_DEFAULT;
  regs_defaults(62)(REG_MT_HIT_MASK_LT11_MSB downto REG_MT_HIT_MASK_LT11_LSB) <= REG_MT_HIT_MASK_LT11_DEFAULT;
  regs_defaults(63)(REG_MT_HIT_MASK_LT12_MSB downto REG_MT_HIT_MASK_LT12_LSB) <= REG_MT_HIT_MASK_LT12_DEFAULT;
  regs_defaults(64)(REG_MT_HIT_MASK_LT13_MSB downto REG_MT_HIT_MASK_LT13_LSB) <= REG_MT_HIT_MASK_LT13_DEFAULT;
  regs_defaults(65)(REG_MT_HIT_MASK_LT14_MSB downto REG_MT_HIT_MASK_LT14_LSB) <= REG_MT_HIT_MASK_LT14_DEFAULT;
  regs_defaults(66)(REG_MT_HIT_MASK_LT15_MSB downto REG_MT_HIT_MASK_LT15_LSB) <= REG_MT_HIT_MASK_LT15_DEFAULT;
  regs_defaults(67)(REG_MT_HIT_MASK_LT16_MSB downto REG_MT_HIT_MASK_LT16_LSB) <= REG_MT_HIT_MASK_LT16_DEFAULT;
  regs_defaults(68)(REG_MT_HIT_MASK_LT17_MSB downto REG_MT_HIT_MASK_LT17_LSB) <= REG_MT_HIT_MASK_LT17_DEFAULT;
  regs_defaults(69)(REG_MT_HIT_MASK_LT18_MSB downto REG_MT_HIT_MASK_LT18_LSB) <= REG_MT_HIT_MASK_LT18_DEFAULT;
  regs_defaults(70)(REG_MT_HIT_MASK_LT19_MSB downto REG_MT_HIT_MASK_LT19_LSB) <= REG_MT_HIT_MASK_LT19_DEFAULT;
  regs_defaults(71)(REG_MT_FINE_DELAYS_LT0_CH0_MSB downto REG_MT_FINE_DELAYS_LT0_CH0_LSB) <= REG_MT_FINE_DELAYS_LT0_CH0_DEFAULT;
  regs_defaults(71)(REG_MT_FINE_DELAYS_LT0_CH1_MSB downto REG_MT_FINE_DELAYS_LT0_CH1_LSB) <= REG_MT_FINE_DELAYS_LT0_CH1_DEFAULT;
  regs_defaults(72)(REG_MT_FINE_DELAYS_LT1_CH0_MSB downto REG_MT_FINE_DELAYS_LT1_CH0_LSB) <= REG_MT_FINE_DELAYS_LT1_CH0_DEFAULT;
  regs_defaults(72)(REG_MT_FINE_DELAYS_LT1_CH1_MSB downto REG_MT_FINE_DELAYS_LT1_CH1_LSB) <= REG_MT_FINE_DELAYS_LT1_CH1_DEFAULT;
  regs_defaults(73)(REG_MT_FINE_DELAYS_LT2_CH0_MSB downto REG_MT_FINE_DELAYS_LT2_CH0_LSB) <= REG_MT_FINE_DELAYS_LT2_CH0_DEFAULT;
  regs_defaults(73)(REG_MT_FINE_DELAYS_LT2_CH1_MSB downto REG_MT_FINE_DELAYS_LT2_CH1_LSB) <= REG_MT_FINE_DELAYS_LT2_CH1_DEFAULT;
  regs_defaults(74)(REG_MT_FINE_DELAYS_LT3_CH0_MSB downto REG_MT_FINE_DELAYS_LT3_CH0_LSB) <= REG_MT_FINE_DELAYS_LT3_CH0_DEFAULT;
  regs_defaults(74)(REG_MT_FINE_DELAYS_LT3_CH1_MSB downto REG_MT_FINE_DELAYS_LT3_CH1_LSB) <= REG_MT_FINE_DELAYS_LT3_CH1_DEFAULT;
  regs_defaults(75)(REG_MT_FINE_DELAYS_LT4_CH0_MSB downto REG_MT_FINE_DELAYS_LT4_CH0_LSB) <= REG_MT_FINE_DELAYS_LT4_CH0_DEFAULT;
  regs_defaults(75)(REG_MT_FINE_DELAYS_LT4_CH1_MSB downto REG_MT_FINE_DELAYS_LT4_CH1_LSB) <= REG_MT_FINE_DELAYS_LT4_CH1_DEFAULT;
  regs_defaults(76)(REG_MT_FINE_DELAYS_LT5_CH0_MSB downto REG_MT_FINE_DELAYS_LT5_CH0_LSB) <= REG_MT_FINE_DELAYS_LT5_CH0_DEFAULT;
  regs_defaults(76)(REG_MT_FINE_DELAYS_LT5_CH1_MSB downto REG_MT_FINE_DELAYS_LT5_CH1_LSB) <= REG_MT_FINE_DELAYS_LT5_CH1_DEFAULT;
  regs_defaults(77)(REG_MT_FINE_DELAYS_LT6_CH0_MSB downto REG_MT_FINE_DELAYS_LT6_CH0_LSB) <= REG_MT_FINE_DELAYS_LT6_CH0_DEFAULT;
  regs_defaults(77)(REG_MT_FINE_DELAYS_LT6_CH1_MSB downto REG_MT_FINE_DELAYS_LT6_CH1_LSB) <= REG_MT_FINE_DELAYS_LT6_CH1_DEFAULT;
  regs_defaults(78)(REG_MT_FINE_DELAYS_LT7_CH0_MSB downto REG_MT_FINE_DELAYS_LT7_CH0_LSB) <= REG_MT_FINE_DELAYS_LT7_CH0_DEFAULT;
  regs_defaults(78)(REG_MT_FINE_DELAYS_LT7_CH1_MSB downto REG_MT_FINE_DELAYS_LT7_CH1_LSB) <= REG_MT_FINE_DELAYS_LT7_CH1_DEFAULT;
  regs_defaults(79)(REG_MT_FINE_DELAYS_LT8_CH0_MSB downto REG_MT_FINE_DELAYS_LT8_CH0_LSB) <= REG_MT_FINE_DELAYS_LT8_CH0_DEFAULT;
  regs_defaults(79)(REG_MT_FINE_DELAYS_LT8_CH1_MSB downto REG_MT_FINE_DELAYS_LT8_CH1_LSB) <= REG_MT_FINE_DELAYS_LT8_CH1_DEFAULT;
  regs_defaults(80)(REG_MT_FINE_DELAYS_LT9_CH0_MSB downto REG_MT_FINE_DELAYS_LT9_CH0_LSB) <= REG_MT_FINE_DELAYS_LT9_CH0_DEFAULT;
  regs_defaults(80)(REG_MT_FINE_DELAYS_LT9_CH1_MSB downto REG_MT_FINE_DELAYS_LT9_CH1_LSB) <= REG_MT_FINE_DELAYS_LT9_CH1_DEFAULT;
  regs_defaults(81)(REG_MT_FINE_DELAYS_LT10_CH0_MSB downto REG_MT_FINE_DELAYS_LT10_CH0_LSB) <= REG_MT_FINE_DELAYS_LT10_CH0_DEFAULT;
  regs_defaults(81)(REG_MT_FINE_DELAYS_LT10_CH1_MSB downto REG_MT_FINE_DELAYS_LT10_CH1_LSB) <= REG_MT_FINE_DELAYS_LT10_CH1_DEFAULT;
  regs_defaults(82)(REG_MT_FINE_DELAYS_LT11_CH0_MSB downto REG_MT_FINE_DELAYS_LT11_CH0_LSB) <= REG_MT_FINE_DELAYS_LT11_CH0_DEFAULT;
  regs_defaults(82)(REG_MT_FINE_DELAYS_LT11_CH1_MSB downto REG_MT_FINE_DELAYS_LT11_CH1_LSB) <= REG_MT_FINE_DELAYS_LT11_CH1_DEFAULT;
  regs_defaults(83)(REG_MT_FINE_DELAYS_LT12_CH0_MSB downto REG_MT_FINE_DELAYS_LT12_CH0_LSB) <= REG_MT_FINE_DELAYS_LT12_CH0_DEFAULT;
  regs_defaults(83)(REG_MT_FINE_DELAYS_LT12_CH1_MSB downto REG_MT_FINE_DELAYS_LT12_CH1_LSB) <= REG_MT_FINE_DELAYS_LT12_CH1_DEFAULT;
  regs_defaults(84)(REG_MT_FINE_DELAYS_LT13_CH0_MSB downto REG_MT_FINE_DELAYS_LT13_CH0_LSB) <= REG_MT_FINE_DELAYS_LT13_CH0_DEFAULT;
  regs_defaults(84)(REG_MT_FINE_DELAYS_LT13_CH1_MSB downto REG_MT_FINE_DELAYS_LT13_CH1_LSB) <= REG_MT_FINE_DELAYS_LT13_CH1_DEFAULT;
  regs_defaults(85)(REG_MT_FINE_DELAYS_LT14_CH0_MSB downto REG_MT_FINE_DELAYS_LT14_CH0_LSB) <= REG_MT_FINE_DELAYS_LT14_CH0_DEFAULT;
  regs_defaults(85)(REG_MT_FINE_DELAYS_LT14_CH1_MSB downto REG_MT_FINE_DELAYS_LT14_CH1_LSB) <= REG_MT_FINE_DELAYS_LT14_CH1_DEFAULT;
  regs_defaults(86)(REG_MT_FINE_DELAYS_LT15_CH0_MSB downto REG_MT_FINE_DELAYS_LT15_CH0_LSB) <= REG_MT_FINE_DELAYS_LT15_CH0_DEFAULT;
  regs_defaults(86)(REG_MT_FINE_DELAYS_LT15_CH1_MSB downto REG_MT_FINE_DELAYS_LT15_CH1_LSB) <= REG_MT_FINE_DELAYS_LT15_CH1_DEFAULT;
  regs_defaults(87)(REG_MT_FINE_DELAYS_LT16_CH0_MSB downto REG_MT_FINE_DELAYS_LT16_CH0_LSB) <= REG_MT_FINE_DELAYS_LT16_CH0_DEFAULT;
  regs_defaults(87)(REG_MT_FINE_DELAYS_LT16_CH1_MSB downto REG_MT_FINE_DELAYS_LT16_CH1_LSB) <= REG_MT_FINE_DELAYS_LT16_CH1_DEFAULT;
  regs_defaults(88)(REG_MT_FINE_DELAYS_LT17_CH0_MSB downto REG_MT_FINE_DELAYS_LT17_CH0_LSB) <= REG_MT_FINE_DELAYS_LT17_CH0_DEFAULT;
  regs_defaults(88)(REG_MT_FINE_DELAYS_LT17_CH1_MSB downto REG_MT_FINE_DELAYS_LT17_CH1_LSB) <= REG_MT_FINE_DELAYS_LT17_CH1_DEFAULT;
  regs_defaults(89)(REG_MT_FINE_DELAYS_LT18_CH0_MSB downto REG_MT_FINE_DELAYS_LT18_CH0_LSB) <= REG_MT_FINE_DELAYS_LT18_CH0_DEFAULT;
  regs_defaults(89)(REG_MT_FINE_DELAYS_LT18_CH1_MSB downto REG_MT_FINE_DELAYS_LT18_CH1_LSB) <= REG_MT_FINE_DELAYS_LT18_CH1_DEFAULT;
  regs_defaults(90)(REG_MT_FINE_DELAYS_LT19_CH0_MSB downto REG_MT_FINE_DELAYS_LT19_CH0_LSB) <= REG_MT_FINE_DELAYS_LT19_CH0_DEFAULT;
  regs_defaults(90)(REG_MT_FINE_DELAYS_LT19_CH1_MSB downto REG_MT_FINE_DELAYS_LT19_CH1_LSB) <= REG_MT_FINE_DELAYS_LT19_CH1_DEFAULT;
  regs_defaults(91)(REG_MT_COARSE_DELAYS_LT0_CH0_MSB downto REG_MT_COARSE_DELAYS_LT0_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT0_CH0_DEFAULT;
  regs_defaults(91)(REG_MT_COARSE_DELAYS_LT0_CH1_MSB downto REG_MT_COARSE_DELAYS_LT0_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT0_CH1_DEFAULT;
  regs_defaults(92)(REG_MT_COARSE_DELAYS_LT1_CH0_MSB downto REG_MT_COARSE_DELAYS_LT1_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT1_CH0_DEFAULT;
  regs_defaults(92)(REG_MT_COARSE_DELAYS_LT1_CH1_MSB downto REG_MT_COARSE_DELAYS_LT1_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT1_CH1_DEFAULT;
  regs_defaults(93)(REG_MT_COARSE_DELAYS_LT2_CH0_MSB downto REG_MT_COARSE_DELAYS_LT2_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT2_CH0_DEFAULT;
  regs_defaults(93)(REG_MT_COARSE_DELAYS_LT2_CH1_MSB downto REG_MT_COARSE_DELAYS_LT2_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT2_CH1_DEFAULT;
  regs_defaults(94)(REG_MT_COARSE_DELAYS_LT3_CH0_MSB downto REG_MT_COARSE_DELAYS_LT3_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT3_CH0_DEFAULT;
  regs_defaults(94)(REG_MT_COARSE_DELAYS_LT3_CH1_MSB downto REG_MT_COARSE_DELAYS_LT3_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT3_CH1_DEFAULT;
  regs_defaults(95)(REG_MT_COARSE_DELAYS_LT4_CH0_MSB downto REG_MT_COARSE_DELAYS_LT4_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT4_CH0_DEFAULT;
  regs_defaults(95)(REG_MT_COARSE_DELAYS_LT4_CH1_MSB downto REG_MT_COARSE_DELAYS_LT4_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT4_CH1_DEFAULT;
  regs_defaults(96)(REG_MT_COARSE_DELAYS_LT5_CH0_MSB downto REG_MT_COARSE_DELAYS_LT5_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT5_CH0_DEFAULT;
  regs_defaults(96)(REG_MT_COARSE_DELAYS_LT5_CH1_MSB downto REG_MT_COARSE_DELAYS_LT5_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT5_CH1_DEFAULT;
  regs_defaults(97)(REG_MT_COARSE_DELAYS_LT6_CH0_MSB downto REG_MT_COARSE_DELAYS_LT6_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT6_CH0_DEFAULT;
  regs_defaults(97)(REG_MT_COARSE_DELAYS_LT6_CH1_MSB downto REG_MT_COARSE_DELAYS_LT6_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT6_CH1_DEFAULT;
  regs_defaults(98)(REG_MT_COARSE_DELAYS_LT7_CH0_MSB downto REG_MT_COARSE_DELAYS_LT7_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT7_CH0_DEFAULT;
  regs_defaults(98)(REG_MT_COARSE_DELAYS_LT7_CH1_MSB downto REG_MT_COARSE_DELAYS_LT7_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT7_CH1_DEFAULT;
  regs_defaults(99)(REG_MT_COARSE_DELAYS_LT8_CH0_MSB downto REG_MT_COARSE_DELAYS_LT8_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT8_CH0_DEFAULT;
  regs_defaults(99)(REG_MT_COARSE_DELAYS_LT8_CH1_MSB downto REG_MT_COARSE_DELAYS_LT8_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT8_CH1_DEFAULT;
  regs_defaults(100)(REG_MT_COARSE_DELAYS_LT9_CH0_MSB downto REG_MT_COARSE_DELAYS_LT9_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT9_CH0_DEFAULT;
  regs_defaults(100)(REG_MT_COARSE_DELAYS_LT9_CH1_MSB downto REG_MT_COARSE_DELAYS_LT9_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT9_CH1_DEFAULT;
  regs_defaults(101)(REG_MT_COARSE_DELAYS_LT10_CH0_MSB downto REG_MT_COARSE_DELAYS_LT10_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT10_CH0_DEFAULT;
  regs_defaults(101)(REG_MT_COARSE_DELAYS_LT10_CH1_MSB downto REG_MT_COARSE_DELAYS_LT10_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT10_CH1_DEFAULT;
  regs_defaults(102)(REG_MT_COARSE_DELAYS_LT11_CH0_MSB downto REG_MT_COARSE_DELAYS_LT11_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT11_CH0_DEFAULT;
  regs_defaults(102)(REG_MT_COARSE_DELAYS_LT11_CH1_MSB downto REG_MT_COARSE_DELAYS_LT11_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT11_CH1_DEFAULT;
  regs_defaults(103)(REG_MT_COARSE_DELAYS_LT12_CH0_MSB downto REG_MT_COARSE_DELAYS_LT12_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT12_CH0_DEFAULT;
  regs_defaults(103)(REG_MT_COARSE_DELAYS_LT12_CH1_MSB downto REG_MT_COARSE_DELAYS_LT12_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT12_CH1_DEFAULT;
  regs_defaults(104)(REG_MT_COARSE_DELAYS_LT13_CH0_MSB downto REG_MT_COARSE_DELAYS_LT13_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT13_CH0_DEFAULT;
  regs_defaults(104)(REG_MT_COARSE_DELAYS_LT13_CH1_MSB downto REG_MT_COARSE_DELAYS_LT13_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT13_CH1_DEFAULT;
  regs_defaults(105)(REG_MT_COARSE_DELAYS_LT14_CH0_MSB downto REG_MT_COARSE_DELAYS_LT14_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT14_CH0_DEFAULT;
  regs_defaults(105)(REG_MT_COARSE_DELAYS_LT14_CH1_MSB downto REG_MT_COARSE_DELAYS_LT14_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT14_CH1_DEFAULT;
  regs_defaults(106)(REG_MT_COARSE_DELAYS_LT15_CH0_MSB downto REG_MT_COARSE_DELAYS_LT15_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT15_CH0_DEFAULT;
  regs_defaults(106)(REG_MT_COARSE_DELAYS_LT15_CH1_MSB downto REG_MT_COARSE_DELAYS_LT15_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT15_CH1_DEFAULT;
  regs_defaults(107)(REG_MT_COARSE_DELAYS_LT16_CH0_MSB downto REG_MT_COARSE_DELAYS_LT16_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT16_CH0_DEFAULT;
  regs_defaults(107)(REG_MT_COARSE_DELAYS_LT16_CH1_MSB downto REG_MT_COARSE_DELAYS_LT16_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT16_CH1_DEFAULT;
  regs_defaults(108)(REG_MT_COARSE_DELAYS_LT17_CH0_MSB downto REG_MT_COARSE_DELAYS_LT17_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT17_CH0_DEFAULT;
  regs_defaults(108)(REG_MT_COARSE_DELAYS_LT17_CH1_MSB downto REG_MT_COARSE_DELAYS_LT17_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT17_CH1_DEFAULT;
  regs_defaults(109)(REG_MT_COARSE_DELAYS_LT18_CH0_MSB downto REG_MT_COARSE_DELAYS_LT18_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT18_CH0_DEFAULT;
  regs_defaults(109)(REG_MT_COARSE_DELAYS_LT18_CH1_MSB downto REG_MT_COARSE_DELAYS_LT18_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT18_CH1_DEFAULT;
  regs_defaults(110)(REG_MT_COARSE_DELAYS_LT19_CH0_MSB downto REG_MT_COARSE_DELAYS_LT19_CH0_LSB) <= REG_MT_COARSE_DELAYS_LT19_CH0_DEFAULT;
  regs_defaults(110)(REG_MT_COARSE_DELAYS_LT19_CH1_MSB downto REG_MT_COARSE_DELAYS_LT19_CH1_LSB) <= REG_MT_COARSE_DELAYS_LT19_CH1_DEFAULT;
  regs_defaults(111)(REG_MT_POSNEGS_LT0_CH0_BIT) <= REG_MT_POSNEGS_LT0_CH0_DEFAULT;
  regs_defaults(111)(REG_MT_POSNEGS_LT0_CH1_BIT) <= REG_MT_POSNEGS_LT0_CH1_DEFAULT;
  regs_defaults(112)(REG_MT_POSNEGS_LT1_CH0_BIT) <= REG_MT_POSNEGS_LT1_CH0_DEFAULT;
  regs_defaults(112)(REG_MT_POSNEGS_LT1_CH1_BIT) <= REG_MT_POSNEGS_LT1_CH1_DEFAULT;
  regs_defaults(113)(REG_MT_POSNEGS_LT2_CH0_BIT) <= REG_MT_POSNEGS_LT2_CH0_DEFAULT;
  regs_defaults(113)(REG_MT_POSNEGS_LT2_CH1_BIT) <= REG_MT_POSNEGS_LT2_CH1_DEFAULT;
  regs_defaults(114)(REG_MT_POSNEGS_LT3_CH0_BIT) <= REG_MT_POSNEGS_LT3_CH0_DEFAULT;
  regs_defaults(114)(REG_MT_POSNEGS_LT3_CH1_BIT) <= REG_MT_POSNEGS_LT3_CH1_DEFAULT;
  regs_defaults(115)(REG_MT_POSNEGS_LT4_CH0_BIT) <= REG_MT_POSNEGS_LT4_CH0_DEFAULT;
  regs_defaults(115)(REG_MT_POSNEGS_LT4_CH1_BIT) <= REG_MT_POSNEGS_LT4_CH1_DEFAULT;
  regs_defaults(116)(REG_MT_POSNEGS_LT5_CH0_BIT) <= REG_MT_POSNEGS_LT5_CH0_DEFAULT;
  regs_defaults(116)(REG_MT_POSNEGS_LT5_CH1_BIT) <= REG_MT_POSNEGS_LT5_CH1_DEFAULT;
  regs_defaults(117)(REG_MT_POSNEGS_LT6_CH0_BIT) <= REG_MT_POSNEGS_LT6_CH0_DEFAULT;
  regs_defaults(117)(REG_MT_POSNEGS_LT6_CH1_BIT) <= REG_MT_POSNEGS_LT6_CH1_DEFAULT;
  regs_defaults(118)(REG_MT_POSNEGS_LT7_CH0_BIT) <= REG_MT_POSNEGS_LT7_CH0_DEFAULT;
  regs_defaults(118)(REG_MT_POSNEGS_LT7_CH1_BIT) <= REG_MT_POSNEGS_LT7_CH1_DEFAULT;
  regs_defaults(119)(REG_MT_POSNEGS_LT8_CH0_BIT) <= REG_MT_POSNEGS_LT8_CH0_DEFAULT;
  regs_defaults(119)(REG_MT_POSNEGS_LT8_CH1_BIT) <= REG_MT_POSNEGS_LT8_CH1_DEFAULT;
  regs_defaults(120)(REG_MT_POSNEGS_LT9_CH0_BIT) <= REG_MT_POSNEGS_LT9_CH0_DEFAULT;
  regs_defaults(120)(REG_MT_POSNEGS_LT9_CH1_BIT) <= REG_MT_POSNEGS_LT9_CH1_DEFAULT;
  regs_defaults(121)(REG_MT_POSNEGS_LT10_CH0_BIT) <= REG_MT_POSNEGS_LT10_CH0_DEFAULT;
  regs_defaults(121)(REG_MT_POSNEGS_LT10_CH1_BIT) <= REG_MT_POSNEGS_LT10_CH1_DEFAULT;
  regs_defaults(122)(REG_MT_POSNEGS_LT11_CH0_BIT) <= REG_MT_POSNEGS_LT11_CH0_DEFAULT;
  regs_defaults(122)(REG_MT_POSNEGS_LT11_CH1_BIT) <= REG_MT_POSNEGS_LT11_CH1_DEFAULT;
  regs_defaults(123)(REG_MT_POSNEGS_LT12_CH0_BIT) <= REG_MT_POSNEGS_LT12_CH0_DEFAULT;
  regs_defaults(123)(REG_MT_POSNEGS_LT12_CH1_BIT) <= REG_MT_POSNEGS_LT12_CH1_DEFAULT;
  regs_defaults(124)(REG_MT_POSNEGS_LT13_CH0_BIT) <= REG_MT_POSNEGS_LT13_CH0_DEFAULT;
  regs_defaults(124)(REG_MT_POSNEGS_LT13_CH1_BIT) <= REG_MT_POSNEGS_LT13_CH1_DEFAULT;
  regs_defaults(125)(REG_MT_POSNEGS_LT14_CH0_BIT) <= REG_MT_POSNEGS_LT14_CH0_DEFAULT;
  regs_defaults(125)(REG_MT_POSNEGS_LT14_CH1_BIT) <= REG_MT_POSNEGS_LT14_CH1_DEFAULT;
  regs_defaults(126)(REG_MT_POSNEGS_LT15_CH0_BIT) <= REG_MT_POSNEGS_LT15_CH0_DEFAULT;
  regs_defaults(126)(REG_MT_POSNEGS_LT15_CH1_BIT) <= REG_MT_POSNEGS_LT15_CH1_DEFAULT;
  regs_defaults(127)(REG_MT_POSNEGS_LT16_CH0_BIT) <= REG_MT_POSNEGS_LT16_CH0_DEFAULT;
  regs_defaults(127)(REG_MT_POSNEGS_LT16_CH1_BIT) <= REG_MT_POSNEGS_LT16_CH1_DEFAULT;
  regs_defaults(128)(REG_MT_POSNEGS_LT17_CH0_BIT) <= REG_MT_POSNEGS_LT17_CH0_DEFAULT;
  regs_defaults(128)(REG_MT_POSNEGS_LT17_CH1_BIT) <= REG_MT_POSNEGS_LT17_CH1_DEFAULT;
  regs_defaults(129)(REG_MT_POSNEGS_LT18_CH0_BIT) <= REG_MT_POSNEGS_LT18_CH0_DEFAULT;
  regs_defaults(129)(REG_MT_POSNEGS_LT18_CH1_BIT) <= REG_MT_POSNEGS_LT18_CH1_DEFAULT;
  regs_defaults(130)(REG_MT_POSNEGS_LT19_CH0_BIT) <= REG_MT_POSNEGS_LT19_CH0_DEFAULT;
  regs_defaults(130)(REG_MT_POSNEGS_LT19_CH1_BIT) <= REG_MT_POSNEGS_LT19_CH1_DEFAULT;

  -- Define writable regs
  regs_writable_arr(0) <= '1';
  regs_writable_arr(7) <= '1';
  regs_writable_arr(9) <= '1';
  regs_writable_arr(10) <= '1';
  regs_writable_arr(51) <= '1';
  regs_writable_arr(52) <= '1';
  regs_writable_arr(53) <= '1';
  regs_writable_arr(54) <= '1';
  regs_writable_arr(55) <= '1';
  regs_writable_arr(56) <= '1';
  regs_writable_arr(57) <= '1';
  regs_writable_arr(58) <= '1';
  regs_writable_arr(59) <= '1';
  regs_writable_arr(60) <= '1';
  regs_writable_arr(61) <= '1';
  regs_writable_arr(62) <= '1';
  regs_writable_arr(63) <= '1';
  regs_writable_arr(64) <= '1';
  regs_writable_arr(65) <= '1';
  regs_writable_arr(66) <= '1';
  regs_writable_arr(67) <= '1';
  regs_writable_arr(68) <= '1';
  regs_writable_arr(69) <= '1';
  regs_writable_arr(70) <= '1';
  regs_writable_arr(71) <= '1';
  regs_writable_arr(72) <= '1';
  regs_writable_arr(73) <= '1';
  regs_writable_arr(74) <= '1';
  regs_writable_arr(75) <= '1';
  regs_writable_arr(76) <= '1';
  regs_writable_arr(77) <= '1';
  regs_writable_arr(78) <= '1';
  regs_writable_arr(79) <= '1';
  regs_writable_arr(80) <= '1';
  regs_writable_arr(81) <= '1';
  regs_writable_arr(82) <= '1';
  regs_writable_arr(83) <= '1';
  regs_writable_arr(84) <= '1';
  regs_writable_arr(85) <= '1';
  regs_writable_arr(86) <= '1';
  regs_writable_arr(87) <= '1';
  regs_writable_arr(88) <= '1';
  regs_writable_arr(89) <= '1';
  regs_writable_arr(90) <= '1';
  regs_writable_arr(91) <= '1';
  regs_writable_arr(92) <= '1';
  regs_writable_arr(93) <= '1';
  regs_writable_arr(94) <= '1';
  regs_writable_arr(95) <= '1';
  regs_writable_arr(96) <= '1';
  regs_writable_arr(97) <= '1';
  regs_writable_arr(98) <= '1';
  regs_writable_arr(99) <= '1';
  regs_writable_arr(100) <= '1';
  regs_writable_arr(101) <= '1';
  regs_writable_arr(102) <= '1';
  regs_writable_arr(103) <= '1';
  regs_writable_arr(104) <= '1';
  regs_writable_arr(105) <= '1';
  regs_writable_arr(106) <= '1';
  regs_writable_arr(107) <= '1';
  regs_writable_arr(108) <= '1';
  regs_writable_arr(109) <= '1';
  regs_writable_arr(110) <= '1';
  regs_writable_arr(111) <= '1';
  regs_writable_arr(112) <= '1';
  regs_writable_arr(113) <= '1';
  regs_writable_arr(114) <= '1';
  regs_writable_arr(115) <= '1';
  regs_writable_arr(116) <= '1';
  regs_writable_arr(117) <= '1';
  regs_writable_arr(118) <= '1';
  regs_writable_arr(119) <= '1';
  regs_writable_arr(120) <= '1';
  regs_writable_arr(121) <= '1';
  regs_writable_arr(122) <= '1';
  regs_writable_arr(123) <= '1';
  regs_writable_arr(124) <= '1';
  regs_writable_arr(125) <= '1';
  regs_writable_arr(126) <= '1';
  regs_writable_arr(127) <= '1';
  regs_writable_arr(128) <= '1';
  regs_writable_arr(129) <= '1';
  regs_writable_arr(130) <= '1';

--==== Registers end ============================================================================
end structural;
