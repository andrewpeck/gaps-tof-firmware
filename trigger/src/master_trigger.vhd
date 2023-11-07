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

library xpm;
use xpm.vcomponents.all;

-- CCB v1 Schematics: http://ohm.bu.edu/~apeck/20220516_gaps_mt_data_package/20220516_GAPS_CCBv1/GAPS_CCBv1_docs/CCB_Schematics.pdf
-- DSI v1 Schematics: http://ohm.bu.edu/~apeck/20220516_gaps_mt_data_package/20220516_GAPS_DSIv1/GAPS_DSIv1_docs/Schematics%20DAQ%20Stack%20Interface.pdf
-- DSI v2 Schematics: http://weber.bu.edu/~apeck/schematics/GAPS/DSI_Schematics_v2.pdf
-- CCB v2 Schematics: http://weber.bu.edu/~apeck/schematics/GAPS/Schematics%20Callisto%20Carrier%20Backplane%20v2.pdf
-- LTB Schematics: http://weber.bu.edu/~apeck/schematics/GAPS/GAPSLocalTriggerV6.pdf
-- Callisto Schematics: https://numato.com/help/wp-content/uploads/2018/06/CallistoK7Sch.pdf

entity gaps_mt is
  generic (

    EN_TMR_IPB_SLAVE_MT : integer range 0 to 1 := 0;

    MAC_ADDR : std_logic_vector (47 downto 0) := x"00_08_20_83_53_00";

    LOOPBACK_MODE : boolean := false;

    MANCHESTER_LOOPBACK : boolean := true;

    CLK_FREQ : integer := 100_000_000;

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
    lt_data_i_p : in  std_logic_vector (NUM_LT_MT_ALL-1 downto 0);
    lt_data_i_n : in  std_logic_vector (NUM_LT_MT_ALL-1 downto 0);

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
    --
    -- hk adcs have been resassigned to EXT_IO due to a pin
    -- conflict on the first revision of the board
    --
    -- hk_cs_n : out std_logic_vector(1 downto 0);
    -- hk_clk  : out std_logic;
    -- hk_dout : in  std_logic; -- master in, slave out
    -- hk_din  : out std_logic; -- master out, slave in

    -- spi_cs_n : in std_logic;
    -- spi_dq   : in std_logic_vector (3 downto 0);

    ext_io  : inout std_logic_vector (13 downto 0) := (others => '0');

    ext_out : out std_logic_vector (3 downto 0);
    ext_in  : in  std_logic_vector (3 downto 0);

    sump_o : out std_logic

    );
end gaps_mt;

architecture structural of gaps_mt is

  constant IP_ADDR      : ip_addr_t := (10, 0, 1, 10);

  signal lt_data_i_pri_p : std_logic_vector (NUM_LT_MT_PRI-1 downto 0) := (others => '0');
  signal lt_data_i_pri_n : std_logic_vector (NUM_LT_MT_PRI-1 downto 0) := (others => '0');
  signal lt_data_i_pri   : std_logic_vector (NUM_LT_MT_PRI-1 downto 0) := (others => '0');
  signal lt_data_i_inv   : std_logic_vector (NUM_LT_MT_PRI-1 downto 0) := (others => '1');

  signal lt_link_rdy     : std_logic_vector (NUM_LT_MT_PRI-1 downto 0) := (others => '1');

  signal lt_data_i_aux_p : std_logic_vector (NUM_LT_MT_AUX-1 downto 0) := (others => '0');
  signal lt_data_i_aux_n : std_logic_vector (NUM_LT_MT_AUX-1 downto 0) := (others => '0');
  signal lt_data_i_aux   : std_logic_vector (NUM_LT_MT_AUX-1 downto 0) := (others => '0');

  signal timestamp       : unsigned (31 downto 0) := (others => '0');
  signal timestamp_latch : std_logic_vector (31 downto 0) := (others => '0');
  signal timestamp_valid : std_logic := '0';

  signal dsi_on_ipb  : std_logic_vector (dsi_on'range);
  signal trigger_ipb : std_logic := '0';

  signal rgmii_rxd_dly     : std_logic_vector(3 downto 0);
  signal rgmii_rx_ctl_dly  : std_logic := '0';
  signal rgmii_rx_clk_dly  : std_logic := '0';

  signal eth_bad_frame : std_logic := '0';
  signal eth_bad_fcs   : std_logic := '0';

  signal sys_clk : std_logic := '0';

  constant RGMII_RXD_DELAY : integer   := 0;
  constant RGMII_RXC_DELAY : integer   := 12;

  signal reset  : std_logic;
  signal locked : std_logic;

  signal clock                                               : std_logic;
  signal clk25, clk200, clk200_90, clk400, clk125, clk125_90 : std_logic;

  signal event_cnt       : std_logic_vector (EVENTCNTB-1 downto 0);
  signal event_cnt_reset : std_logic;

  signal rb_resync : std_logic := '0';
  signal resync    : std_logic := '0';

  signal coarse_delays : lt_coarse_delays_array_t
    := (others => (others => '0'));

  signal lt_input_stretch : std_logic_vector (3 downto 0) := (others => '0');

  signal dsi_link_en : std_logic_vector(lt_data_i_pri_p'range);

  signal discrim, hits_masked, hits_xtrig : threshold_array_t;   -- 1d array of 25 * 8 discrim

  signal channel_mask       : t_std8_array (NUM_LTS-1 downto 0);
  signal discrim_1bit       : t_std8_array (NUM_LTS-1 downto 0);
  signal ltb_hit, ltb_hit_r, ltb_hit_rr : std_logic_vector (24 downto 0) := (others => '0');


  signal lost_trigger   : std_logic;
  signal global_trigger : std_logic;  -- single bit == the baloon triggered somewhere
  signal pre_trigger    : std_logic;  -- 1 clock cycle earlier than global_trigger
  signal global_busy    : std_logic;

  signal trig_rate       : std_logic_vector (23 downto 0) := (others => '0');
  signal lost_trig_rate  : std_logic_vector (23 downto 0) := (others => '0');

  signal trig_gen_rate   : std_logic_vector (31 downto 0) := (others => '0');
  signal trig_gen        : std_logic                      := '0';
  signal ext_trigger     : std_logic := '0';
  signal ext_trigger_r0  : std_logic := '0';
  signal ext_trigger_r1  : std_logic := '0';
  signal ext_trigger_r2  : std_logic := '0';

  signal hit_thresh   : std_logic_vector (1 downto 0);
  signal trig_mask_a  : std_logic_vector (31 downto 0);
  signal trig_mask_b  : std_logic_vector (31 downto 0);
  signal any_trig_en  : std_logic;

  signal ssl_trig_top_bot_en       : std_logic;
  signal ssl_trig_topedge_bot_en   : std_logic;
  signal ssl_trig_top_botedge_en   : std_logic;
  signal ssl_trig_topmid_botmid_en : std_logic;

  signal gaps_trigger_en  : std_logic;
  signal require_beta     : std_logic;
  signal inner_tof_thresh : std_logic_vector (7 downto 0);
  signal outer_tof_thresh : std_logic_vector (7 downto 0);
  signal total_tof_thresh : std_logic_vector (7 downto 0);

  signal ext_trigger_holdoff : integer range 0 to 31 := 0;

  signal tiu_gps           : std_logic_vector (8*6-1 downto 0);
  signal tiu_gps_valid     : std_logic;

  signal tiu_emulation_mode : std_logic;
  signal tiu_emu_busy_cnt   : std_logic_vector (17 downto 0);

  signal tiu_busy_i    : std_logic;
  signal tiu_serial_o  : std_logic;
  signal tiu_gps_i     : std_logic;
  signal tiu_trigger_o : std_logic;
  signal tiu_bad       : std_logic;
  signal tiu_use_aux   : std_logic := '0';

  -- 1 bit trigger for rb; this is just the OR of the channel_select
  signal rb_triggers    : std_logic_vector (NUM_RBS-1 downto 0);

  -- 1 bit for each paddle; 1 to select it for readout in the hitmask
  signal channel_select : channel_bitmask_t;

  signal fb_clk, fb_clk_i : std_logic_vector (fb_clk_p'range);
  signal fb_clock_rates   : t_std32_array(fb_clk_p'range);
  signal fb_clk_ok        : std_logic_vector (fb_clk_p'range);
  constant FB_CLK_FREQ    : integer := 20_000_000;
  constant FB_CLK_TOL     : integer := 50_000;

  signal clock_rate : std_logic_vector (31 downto 0);

  -- xadc

  signal calibration : std_logic_vector(11 downto 0);
  signal vccpint     : std_logic_vector(11 downto 0);
  signal vccpaux     : std_logic_vector(11 downto 0);
  signal vccoddr     : std_logic_vector(11 downto 0);
  signal temp        : std_logic_vector(11 downto 0);
  signal vccint      : std_logic_vector(11 downto 0);
  signal vccaux      : std_logic_vector(11 downto 0);
  signal vccbram     : std_logic_vector(11 downto 0);

  --------------------------------------------------------------------------------
  -- DAQ
  --------------------------------------------------------------------------------

  signal daq_data        : std_logic_vector (15 downto 0) := (others => '0');
  signal daq_data_xfifo  : std_logic_vector (31 downto 0) := (others => '0');
  signal daq_data_valid  : std_logic                      := '0';
  signal daq_valid_xfifo : std_logic                      := '0';
  signal daq_empty       : std_logic                      := '0';
  signal daq_full        : std_logic                      := '0';
  signal daq_rd_en       : std_logic                      := '0';
  signal daq_reset       : std_logic                      := '0';

  signal daq_last             : std_logic                      := '0';
  signal daq_pkt_size         : std_logic_vector (15 downto 0) := (others => '0');
  signal daq_pkt_size_xfifo   : std_logic_vector (15 downto 0) := (others => '0');
  signal daq_pkt_size_masked  : std_logic_vector (15 downto 0) := (others => '0');
  signal daq_pkt_size_rd_en   : std_logic                      := '0';
  signal daq_pkt_size_rd_en_r : std_logic                      := '0';
  signal daq_pkt_size_rd_done : std_logic                      := '0';
  signal daq_pkt_size_valid   : std_logic                      := '0';
  signal daq_pkt_size_empty   : std_logic                      := '0';

  --------------------------------------------------------------------------------
  -- IPbus / wishbone
  --------------------------------------------------------------------------------

  signal loopback : std_logic_vector (31 downto 0) := (others => '0');

  signal ipb_reset     : std_logic;
  signal hit_cnt_reset : std_logic;
  signal cnt_snap      : std_logic;
  signal ipb_clk       : std_logic;

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
  signal hit_count_0 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_1 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_2 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_3 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_4 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_5 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_6 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_7 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_8 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_9 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_10 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_11 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_12 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_13 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_14 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_15 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_16 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_17 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_18 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_19 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_20 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_21 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_22 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_23 : std_logic_vector (23 downto 0) := (others => '0');
  signal hit_count_24 : std_logic_vector (23 downto 0) := (others => '0');
  signal eth_bad_frame_cnt : std_logic_vector (15 downto 0) := (others => '0');
  signal eth_bad_fcs_cnt : std_logic_vector (15 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------

  signal hk_ext_cs_n : std_logic_vector(1 downto 0);
  signal hk_ext_clk  : std_logic;
  signal hk_ext_miso : std_logic; -- master in, slave out
  signal hk_ext_mosi  :std_logic; -- master out, slave in

  signal hk_scl : std_logic := '0';
  signal hk_sda : std_logic := '0';

begin

  process (clock, locked) is
  begin
    if (locked = '0') then
      reset <= '1';
    elsif (rising_edge(clock)) then
      reset <= '0';
    end if;
  end process;

  clk_src_sel <= '0';

  ipb_reset <= reset;
  ipb_clk   <= clock;

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

  -- mtb can detect if it is at UCLA through looping a 1 out from EXT_IO3
  -- and into EXT_IO2.. a jumper should be placed across these two pins
  -- disabled to make room for i2c 5/4/2023

  eth_infra_inst : entity work.eth_infra
    port map (
      clock        => clock,
      reset        => reset,
      gtx_clk      => clk125,
      gtx_clk90    => clk125_90,

      rx_bad_frame_o => eth_bad_frame,
      rx_bad_fcs_o   => eth_bad_fcs,

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

  clocking : entity work.clocking
    generic map (
      NUM_DSI => NUM_DSI,
      EXT_CLK => false
      )
    port map (
      clk_p     => clk_p,
      clk_n     => clk_n,

      sys_clk_i => sys_clk_i,
      sys_clk_o => sys_clk,

      lvs_sync => lvs_sync,
      ccb_sync => lvs_sync_ccb,

      clk25     => clk25,               -- system clock
      clk100    => clock,               -- system clock
      clk200_90 => clk200_90,           -- 200mhz for LTB
      clk200    => clk200,              -- 200mhz for iodelay / LTB
      clk400    => clk400,              -- 400mhz for LTB
      clk125    => clk125,              -- for ethernet
      clk125_90 => clk125_90,           -- for ethernet
      locked    => locked               -- mmcm locked
      );

  fb_clk_gen : for I in fb_clk_p'range generate
  begin
    fb_clk_ibuf : ibufds
      generic map (
        diff_term    => true,  -- differential termination
        ibuf_low_pwr => true,  -- low power (true) vs. performance (false) setting for referenced i/o standards
        iostandard   => "default"
        )
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
        clk_a_freq => CLK_FREQ
        )
      port map (
        reset => reset,
        clk_a => sys_clk,
        clk_b => fb_clk(I),
        rate  => fb_clock_rates(I)
        );

    process (sys_clk) is
    begin
      if (rising_edge(sys_clk)) then
        if (to_int(fb_clock_rates(I)) > FB_CLK_FREQ - FB_CLK_TOL and
            to_int(fb_clock_rates(I)) < FB_CLK_FREQ + FB_CLK_TOL) then
          fb_clk_ok(I) <= '1';
        else
          fb_clk_ok(I) <= '0';
        end if;
      end if;
    end process;

  end generate;


  frequency_counter_inst : entity work.frequency_counter
    generic map (
      clk_a_freq => CLK_FREQ
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

  -- automatically disable dsi links which have bad feedback clocks
  process (clk200) is
  begin
    if (rising_edge(clk200)) then
      dsi_link_en <= repeat(fb_clk_ok(4), NUM_LT_MT_PRI/NUM_DSI) &
                     repeat(fb_clk_ok(3), NUM_LT_MT_PRI/NUM_DSI) &
                     repeat(fb_clk_ok(2), NUM_LT_MT_PRI/NUM_DSI) &
                     repeat(fb_clk_ok(1), NUM_LT_MT_PRI/NUM_DSI) &
                     repeat(fb_clk_ok(0), NUM_LT_MT_PRI/NUM_DSI);
    end if;
  end process;

  -- dole out all 75 lt data inputs into 50 primary inputs,
  -- and 25 auxillary inputs
  pri_assign : for I in 0 to NUM_LT_MT_PRI - 1 generate
  begin
    evengen : if (I mod 2 = 0) generate
      lt_data_i_pri_p(I) <= lt_data_i_p(I*2 - I/2);
      lt_data_i_pri_n(I) <= lt_data_i_n(I*2 - I/2);
    end generate;
    oddgen : if (I mod 2 = 1) generate
      lt_data_i_pri_p(I) <= lt_data_i_p(I*2 - (I+1)/2);
      lt_data_i_pri_n(I) <= lt_data_i_n(I*2 - (I+1)/2);
    end generate;

    ibufdata : IBUFDS
      generic map (                     --
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true   -- Low power="TRUE", Highest performance="FALSE"
        )
      port map (
        O  => lt_data_i_pri(I),
        I  => lt_data_i_pri_p(I),
        IB => lt_data_i_pri_n(I)
        );
  end generate;

  aux_assign : for I in 0 to NUM_LT_MT_AUX - 1 generate
      lt_data_i_aux_p(I) <= lt_data_i_p(I*3+2);
      lt_data_i_aux_n(I) <= lt_data_i_n(I*3+2);
  end generate;

  noloop_r : if (not LOOPBACK_MODE) generate
    lt_rx : entity work.lt_rx
      port map (

        reset_i => reset,

        -- system clock
        clk   => clk200,
        clk90 => clk200_90,
        clk2x => clk400,

        -- clock and data from lt boards
        data_i  => lt_data_i_pri,
        inv     => lt_data_i_inv,
        rdy_o   => lt_link_rdy,
        link_en => dsi_link_en,

        -- sr delay settings (in units of 1 clock cycle)
        coarse_delays_i => coarse_delays,
        stretch         => lt_input_stretch,

        -- hit outputs
        hits_o => discrim
        );

    dsi_on <= dsi_on_ipb;

  end generate;

  --------------------------------------------------------------------------------
  -- core trigger logic:
  --------------------------------------------------------------------------------
  --
  --   take in a list of discrim on channels
  --   return a global OR of the trigger list
  --   and a list of channels to be read out
  --
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      for I in 0 to discrim_1bit'length-1 loop
        for J in 0 to discrim_1bit(0)'length-1 loop
          if (hits_masked(I*8+J) /= "00") then
            discrim_1bit(I)(J) <= '1';
          else
            discrim_1bit(I)(J) <= '0';
          end if;
        end loop;
      end loop;

      for I in ltb_hit'range loop
        ltb_hit_r(I)  <= or_reduce(discrim_1bit(I));
        ltb_hit_rr(I) <= ltb_hit_r(I);
        ltb_hit(I)    <= ltb_hit_rr(I) and not ltb_hit_r(I);
      end loop;

    end if;
  end process;

  -- optionally mask off hot channels
  process (all) is
  begin
    for I in 0 to hits_masked'length-1 loop
      hits_masked(I) <= discrim(I) and repeat(not channel_mask(I / 8)(I mod 8), hits_masked(I)'length);
    end loop;
  end process;

  --------------------------------------------------------------------------------
  -- Master Trigger Logic
  --------------------------------------------------------------------------------

  trigger : entity work.trigger
    port map (

      -- clock and reset
      clk             => clock,
      reset           => reset,
      event_cnt_reset => event_cnt_reset,

      -- discrim from input stage (20x16 array of discrim), along with a delayed
      -- output copy of the hits that goes to the DAQ module
      hits_i => hits_masked,
      hits_o => hits_xtrig,

      -- different trigger options are enabled / disabled here

      ssl_trig_top_bot_en       => ssl_trig_top_bot_en,
      ssl_trig_topedge_bot_en   => ssl_trig_topedge_bot_en,
      ssl_trig_top_botedge_en   => ssl_trig_top_botedge_en,
      ssl_trig_topmid_botmid_en => ssl_trig_topmid_botmid_en,

      gaps_trigger_en   => gaps_trigger_en,
      require_beta      => require_beta,
      inner_tof_thresh  => inner_tof_thresh,
      outer_tof_thresh  => outer_tof_thresh,
      total_tof_thresh  => total_tof_thresh,

      busy_i    => global_busy,
      rb_busy_i => (others => '0'),

      all_triggers_are_global => '1',

      single_hit_en_i => any_trig_en,
      trig_mask_a     => trig_mask_a,
      trig_mask_b     => trig_mask_b,
      hit_thresh      => hit_thresh,

      -- force_trigger_i => trigger_ipb or trig_gen or ext_trigger,
      force_trigger_i => trigger_ipb or trig_gen,

      event_cnt_o => event_cnt,

      -- ouptut from trigger logic
      lost_trigger_o   => lost_trigger,   --
      global_trigger_o => global_trigger, -- OR of the trigger menu
      pre_trigger_o    => pre_trigger,
      rb_triggers_o    => rb_triggers,    -- 39 trigger outputs  (-1 per rb)
      channel_select_o => channel_select  -- trigger output (197 trigger outputs)
      );

  --------------------------------------------------------------------------------
  -- Random Trigger Generator
  --------------------------------------------------------------------------------

  trig_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clock,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => trig_gen_rate,
      trig       => trig_gen
      );

  --------------------------------------------------------------------------------
  -- External Trigger Input
  --
  -- Take the trigger from external IO0, debounce it and apply a holdoff to
  -- prevent retriggering on ringing from the input
  --------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then
      ext_trigger_r0 <= ext_io(0);
      ext_trigger_r1 <= ext_trigger_r0;
      ext_trigger_r2 <= ext_trigger_r1;

      if (ext_trigger_r2 = '1')  then
        ext_trigger_holdoff <= 31;
      elsif  (ext_trigger_holdoff > 0) then
        ext_trigger_holdoff <= ext_trigger_holdoff - 1;
      end if;

      if (ext_trigger_holdoff=0 and ext_trigger_r2='1') then
        ext_trigger <= '1';
      else
        ext_trigger <= '0';
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Rate Counter
  --------------------------------------------------------------------------------

  rate_counter_trigger : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => std_logic_vector(to_unsigned(CLK_FREQ,32)),
      g_COUNTER_WIDTH => 24
      )
    port map (
      clk_i   => clock,
      reset_i => reset,
      en_i    => global_trigger,
      rate_o  => trig_rate
      );

  rate_counter_lost_trigger : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => std_logic_vector(to_unsigned(CLK_FREQ,32)),
      g_COUNTER_WIDTH => 24
      )
    port map (
      clk_i   => clock,
      reset_i => reset,
      en_i    => lost_trigger,
      rate_o  => lost_trig_rate
      );

  --------------------------------------------------------------------------------
  -- Readout Board Transmitter
  --
  -- takes in triggers, outputs a serialized packet to send to the readout board
  --
  --------------------------------------------------------------------------------

  noloop_t : if (not LOOPBACK_MODE) generate

    resync <= '1' when rb_resync = '1' or (global_trigger = '1' and event_cnt = x"00000000") else '0';

    -- extend the trigger pulses by a few clocks for the fast to slow clock transition
    trg_tx_gen : for I in 0 to NUM_RBS-1 generate
      signal trg_extend : std_logic_vector (7 downto 0) := (others => '0');
      signal clk        : std_logic                     := '0';
      signal trg        : std_logic                     := '0';
    begin

      process (clock) is
      begin
        if (rising_edge(clock)) then
          if (rb_triggers(I)='1') then
            trg_extend <= (others => '1');
          else
            trg_extend <= '0' & trg_extend(trg_extend'length-1 downto 1);
          end if;
        end if;
      end process;

      even : if (I mod 2 = 0) generate
        clk <= clk25;
      end generate;

      odd : if (I mod 2 = 1) generate
        clk <= clk25;
      end generate;

      trg    <= or_reduce(trg_extend);

      rb_tx_inst : entity work.rb_tx
        generic map (
          EVENTCNTB => EVENTCNTB,
          MASKCNTB  => NUM_RB_CHANNELS
          )
        port map (
          clock => clk,
          reset => reset,

          trg_i       => trg,
          resync_i    => resync,
          event_cnt_i => event_cnt,
          ch_mask_i   => (others => '1'), -- FIXME: this should come from the
                                          -- trigger block once the logic is in
                                          -- place, but for now just read all channels
          serial_o => rb_data_o(I)

          );

    end generate;
  end generate;

  --------------------------------------------------------------------------------
  -- TIU Interface
  --------------------------------------------------------------------------------

  tiu_busy_i <= ext_in(0) when tiu_use_aux = '0' else ext_in(2);
  tiu_gps_i  <= ext_in(1) when tiu_use_aux = '0' else ext_in(3);
  ext_out(0) <= tiu_serial_o; -- pri
  ext_out(2) <= tiu_serial_o; -- aux

  process (clk200) is
  begin
    if (rising_edge(clk200)) then
      ext_out(1) <= tiu_trigger_o; -- pri
      ext_out(3) <= tiu_trigger_o; -- aux
    end if;
  end process;

  tiu_inst : entity work.tiu
    generic map (
      FREQ       => CLK_FREQ,
      TIMESTAMPB => timestamp'length,
      GPSB       => tiu_gps'length,
      EVENTCNTB  => event_cnt'length)
    port map (
      clock             => clock,
      reset             => reset,

      -- tiu physical signals
      tiu_busy_i    => tiu_busy_i,
      tiu_serial_o  => tiu_serial_o,
      tiu_gps_i     => tiu_gps_i,
      tiu_trigger_o => tiu_trigger_o,

      tiu_bad_o     => tiu_bad,

      -- config
      send_event_cnt_on_timeout => '1',
      tiu_emulation_mode        => tiu_emulation_mode,
      tiu_emu_busy_cnt_i        => tiu_emu_busy_cnt,

      -- mt trigger signals
      trigger_i         => pre_trigger or global_trigger,
      event_cnt_i       => event_cnt,
      timestamp_i       => std_logic_vector(timestamp),

      -- outputs

      global_busy_o     => global_busy,

      tiu_gps_valid_o   => tiu_gps_valid,
      tiu_gps_o         => tiu_gps,

      timestamp_o       => timestamp_latch,
      timestamp_valid_o => timestamp_valid
      );

  -------------------------------------------------------------------------------
  -- Timestamp
  -------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then
      if (resync='1' or reset = '1') then
        timestamp <= (others => '0');
      else
        timestamp <= timestamp + 1;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- SPI master
  --
  -- MCP3208-BI/SL
  -- https://ww1.microchip.com/downloads/en/DeviceDoc/21298e.pdf
  -- https://opencores.org/websvn/filedetails?repname=spi&path=%2Fspi%2Ftrunk%2Fdoc%2Fspi.pdf
  --
  --------------------------------------------------------------------------------

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
  -- I2C Master
  --------------------------------------------------------------------------------

  ipbus_i2c_master_inst : entity work.ipbus_i2c_master
    port map (
      clk     => clock,
      rst     => reset,
      ipb_in  => ipb_mosi_arr(2),
      ipb_out => ipb_miso_arr(2),
      scl_pad => hk_scl,
      sda_pad => hk_sda
      );

  ext_io(3) <= hk_scl;
  ext_io(2) <= hk_sda;

  --------------------------------------------------------------------------------
  -- MTB DAQ
  --------------------------------------------------------------------------------

  mtb_daq_inst : entity work.mtb_daq
    port map (
      clock           => clock,
      reset_i         => reset,
      trigger_i       => global_trigger,
      event_cnt_i     => event_cnt,
      timestamp_i     => std_logic_vector(timestamp),
      tiu_timestamp_i => timestamp_latch,
      tiu_gps_i       => tiu_gps,
      hits_i          => hits_xtrig,
      data_o          => daq_data,
      data_valid_o    => daq_data_valid,
      data_last_o     => daq_last,
      data_size_o     => daq_pkt_size
      );

  -- FIXME: a full fifo will NOT be handled gracefully.. the event queue and
  -- data fifo will become desynced, the data fifo will have partial events at
  -- the tail.. it will be a mess. should extract the ALMOST_FULL signal from
  -- the fifo and just disable writing to either FIFO if there is not enough
  -- room for the biggest possible event

  mtb_fifo_inst : entity work.fifo_sync
    generic map (
      DEPTH     => 4*16384,
      WR_WIDTH  => 16,
      RD_WIDTH  => 32
      )
    port map (
      rst    => reset or daq_reset,
      clk    => clock,

      -- in
      wr_en  => daq_data_valid,
      din    => daq_data,

      -- out
      rd_en  => daq_rd_en,
      dout   => daq_data_xfifo,
      valid  => daq_valid_xfifo,

      -- status
      full   => daq_full,
      empty  => daq_empty
      );

  mtb_event_fifo_inst : entity work.fifo_sync
    generic map (
      DEPTH     => 8192,
      WR_WIDTH  => 16,
      RD_WIDTH  => 16,
      READ_MODE => "std",
      RD_LATENCY => 1
      )
    port map (
      rst    => reset or daq_reset or daq_empty,
      clk    => clock,

      -- in
      wr_en  => daq_last,
      din    => daq_pkt_size,

      -- out
      rd_en  => daq_pkt_size_rd_en,
      dout   => daq_pkt_size_xfifo,
      valid  => daq_pkt_size_valid,

      -- status
      full   => open,
      empty  => daq_pkt_size_empty
      );


  -- give the fifo a clock to read out
  process (clock) is
  begin
    if (rising_edge(clock)) then

      daq_pkt_size_rd_en_r <= daq_pkt_size_rd_en;
      daq_pkt_size_rd_done <= daq_pkt_size_rd_en_r;

      if (daq_pkt_size_rd_en_r='1') then
        -- make sure the size reads zero when the fifo is empty
        if (daq_pkt_size_valid='1') then
          daq_pkt_size_masked <= daq_pkt_size_xfifo;
        else
          daq_pkt_size_masked <= (others => '0');
        end if;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Signal Sump
  --------------------------------------------------------------------------------

  sump_o <= '0';

  --------------------------------------------------------------------------------
  -- ILA
  --------------------------------------------------------------------------------

  not_loopback_gen : if (not LOOPBACK_MODE) generate

    ila_mt_inst : ila_mt
      port map (
        clk                  => clock,
        probe0(0)            => rb_data_o(0),
        probe1(0)            => global_trigger,
        probe2(31 downto 0)  => loopback,
        probe2(39 downto 32) => eth_bad_frame_cnt (7 downto 0),
        probe2(47 downto 40) => eth_bad_fcs_cnt (7 downto 0),
        probe2(52 downto 48) => fb_clk_ok,
        probe2(57 downto 53) => dsi_on,
        probe2(58)           => tiu_busy_i,
        probe2(59)           => tiu_gps_i,
        probe2(60)           => tiu_serial_o,
        probe2(61)           => tiu_trigger_o,
        probe2(62)           => eth_bad_fcs,
        probe2(74 downto 63) => (others => '0'),
        probe3(3 downto 0)   => (others => '0'),
        probe3(4)            => ext_in(0),
        probe3(5)            => ext_in(1),
        probe3(6)            => eth_bad_frame,
        probe3(7)            => ext_out(0),
        probe4(4 downto 0)   => lvs_sync,
        probe4(5)            => daq_data_valid,
        probe4(6)            => ext_trigger,
        probe4(7)            => ext_out(1),
        probe5(0)            => lvs_sync_ccb,
        probe6(0)            => hk_ext_clk,
        probe7(0)            => hk_ext_mosi,
        probe8(0)            => hk_ext_miso,
        probe9               => hk_ext_cs_n,
        probe10              => fb_clock_rates(0),
        probe11              => lt_data_i_pri(31 downto 0),
        probe12(31 downto 0) => timestamp_latch,
        probe13              => x"0000" & daq_data,
        probe14              => event_cnt
        );
  end generate;

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
        probe10    => fb_clock_rates(0),
        probe11    => fb_clock_rates(1),
        probe12    => fb_clock_rates(2),
        probe13    => fb_clock_rates(3),
        probe14    => fb_clock_rates(4)
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
  regs_addresses(10)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0a";
  regs_addresses(11)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0b";
  regs_addresses(12)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0c";
  regs_addresses(13)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0d";
  regs_addresses(14)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0e";
  regs_addresses(15)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"0f";
  regs_addresses(16)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"10";
  regs_addresses(17)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"11";
  regs_addresses(18)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"12";
  regs_addresses(19)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"13";
  regs_addresses(20)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"14";
  regs_addresses(21)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"15";
  regs_addresses(22)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"16";
  regs_addresses(23)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"17";
  regs_addresses(24)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"18";
  regs_addresses(25)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"19";
  regs_addresses(26)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1a";
  regs_addresses(27)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1b";
  regs_addresses(28)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1c";
  regs_addresses(29)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1d";
  regs_addresses(30)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"1e";
  regs_addresses(31)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"20";
  regs_addresses(32)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"21";
  regs_addresses(33)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"22";
  regs_addresses(34)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"23";
  regs_addresses(35)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"24";
  regs_addresses(36)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"25";
  regs_addresses(37)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"26";
  regs_addresses(38)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"27";
  regs_addresses(39)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"28";
  regs_addresses(40)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"29";
  regs_addresses(41)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2a";
  regs_addresses(42)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2b";
  regs_addresses(43)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2c";
  regs_addresses(44)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2d";
  regs_addresses(45)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2e";
  regs_addresses(46)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"2f";
  regs_addresses(47)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"30";
  regs_addresses(48)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"31";
  regs_addresses(49)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"32";
  regs_addresses(50)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"33";
  regs_addresses(51)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"34";
  regs_addresses(52)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"35";
  regs_addresses(53)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"36";
  regs_addresses(54)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"37";
  regs_addresses(55)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"38";
  regs_addresses(56)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"39";
  regs_addresses(57)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"3a";
  regs_addresses(58)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"3d";
  regs_addresses(59)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"50";
  regs_addresses(60)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"51";
  regs_addresses(61)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"52";
  regs_addresses(62)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"53";
  regs_addresses(63)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"54";
  regs_addresses(64)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"55";
  regs_addresses(65)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"56";
  regs_addresses(66)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"57";
  regs_addresses(67)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"58";
  regs_addresses(68)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"59";
  regs_addresses(69)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5a";
  regs_addresses(70)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5b";
  regs_addresses(71)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5c";
  regs_addresses(72)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5d";
  regs_addresses(73)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5e";
  regs_addresses(74)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"5f";
  regs_addresses(75)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"60";
  regs_addresses(76)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"61";
  regs_addresses(77)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"62";
  regs_addresses(78)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"63";
  regs_addresses(79)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"64";
  regs_addresses(80)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"65";
  regs_addresses(81)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"66";
  regs_addresses(82)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"67";
  regs_addresses(83)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"68";
  regs_addresses(84)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c0";
  regs_addresses(85)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c1";
  regs_addresses(86)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c2";
  regs_addresses(87)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c3";
  regs_addresses(88)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c4";
  regs_addresses(89)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c5";
  regs_addresses(90)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c6";
  regs_addresses(91)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c7";
  regs_addresses(92)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c8";
  regs_addresses(93)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c9";
  regs_addresses(94)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ca";
  regs_addresses(95)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cb";
  regs_addresses(96)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cc";
  regs_addresses(97)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cd";
  regs_addresses(98)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ce";
  regs_addresses(99)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cf";
  regs_addresses(100)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d0";
  regs_addresses(101)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d1";
  regs_addresses(102)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d2";
  regs_addresses(103)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d3";
  regs_addresses(104)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d4";
  regs_addresses(105)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d5";
  regs_addresses(106)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d6";
  regs_addresses(107)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d7";
  regs_addresses(108)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d8";
  regs_addresses(109)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d9";
  regs_addresses(110)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"da";
  regs_addresses(111)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"db";
  regs_addresses(112)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"dc";
  regs_addresses(113)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"dd";
  regs_addresses(114)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"de";
  regs_addresses(115)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"df";
  regs_addresses(116)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e0";
  regs_addresses(117)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e1";
  regs_addresses(118)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e2";
  regs_addresses(119)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e3";
  regs_addresses(120)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e4";
  regs_addresses(121)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e5";
  regs_addresses(122)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e6";
  regs_addresses(123)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e7";
  regs_addresses(124)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e8";
  regs_addresses(125)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e9";
  regs_addresses(126)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ea";
  regs_addresses(127)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"eb";
  regs_addresses(128)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ec";
  regs_addresses(129)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ed";
  regs_addresses(130)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ee";
  regs_addresses(131)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ef";
  regs_addresses(132)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f0";
  regs_addresses(133)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f1";
  regs_addresses(134)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"20";
  regs_addresses(135)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"21";
  regs_addresses(136)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"22";
  regs_addresses(137)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"23";
  regs_addresses(138)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"00";
  regs_addresses(139)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"01";
  regs_addresses(140)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"02";
  regs_addresses(141)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"03";
  regs_addresses(142)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"04";
  regs_addresses(143)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"05";
  regs_addresses(144)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"06";
  regs_addresses(145)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"07";

  -- Connect read signals
  regs_read_arr(0)(REG_LOOPBACK_MSB downto REG_LOOPBACK_LSB) <= loopback;
  regs_read_arr(1)(REG_CLOCK_RATE_MSB downto REG_CLOCK_RATE_LSB) <= clock_rate;
  regs_read_arr(2)(REG_FB_CLOCK_RATE_0_MSB downto REG_FB_CLOCK_RATE_0_LSB) <= fb_clock_rates(0);
  regs_read_arr(3)(REG_FB_CLOCK_RATE_1_MSB downto REG_FB_CLOCK_RATE_1_LSB) <= fb_clock_rates(1);
  regs_read_arr(4)(REG_FB_CLOCK_RATE_2_MSB downto REG_FB_CLOCK_RATE_2_LSB) <= fb_clock_rates(2);
  regs_read_arr(5)(REG_FB_CLOCK_RATE_3_MSB downto REG_FB_CLOCK_RATE_3_LSB) <= fb_clock_rates(3);
  regs_read_arr(6)(REG_FB_CLOCK_RATE_4_MSB downto REG_FB_CLOCK_RATE_4_LSB) <= fb_clock_rates(4);
  regs_read_arr(7)(REG_DSI_ON_MSB downto REG_DSI_ON_LSB) <= dsi_on_ipb;
  regs_read_arr(9)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= trig_gen_rate;
  regs_read_arr(11)(REG_ANY_TRIG_EN_BIT) <= any_trig_en;
  regs_read_arr(13)(REG_EVENT_CNT_MSB downto REG_EVENT_CNT_LSB) <= event_cnt;
  regs_read_arr(14)(REG_TIU_EMULATION_MODE_BIT) <= tiu_emulation_mode;
  regs_read_arr(14)(REG_TIU_USE_AUX_LINK_BIT) <= tiu_use_aux;
  regs_read_arr(14)(REG_TIU_EMU_BUSY_CNT_MSB downto REG_TIU_EMU_BUSY_CNT_LSB) <= tiu_emu_busy_cnt;
  regs_read_arr(15)(REG_TIU_BAD_BIT) <= tiu_bad;
  regs_read_arr(15)(REG_LT_INPUT_STRETCH_MSB downto REG_LT_INPUT_STRETCH_LSB) <= lt_input_stretch;
  regs_read_arr(17)(REG_EVENT_QUEUE_DATA_MSB downto REG_EVENT_QUEUE_DATA_LSB) <= daq_data_xfifo;
  regs_read_arr(18)(REG_EVENT_QUEUE_FULL_BIT) <= daq_full;
  regs_read_arr(18)(REG_EVENT_QUEUE_EMPTY_BIT) <= daq_empty;
  regs_read_arr(19)(REG_EVENT_QUEUE_SIZE_MSB downto REG_EVENT_QUEUE_SIZE_LSB) <= daq_pkt_size_masked;
  regs_read_arr(20)(REG_INNER_TOF_THRESH_MSB downto REG_INNER_TOF_THRESH_LSB) <= inner_tof_thresh;
  regs_read_arr(20)(REG_OUTER_TOF_THRESH_MSB downto REG_OUTER_TOF_THRESH_LSB) <= outer_tof_thresh;
  regs_read_arr(20)(REG_TOTAL_TOF_THRESH_MSB downto REG_TOTAL_TOF_THRESH_LSB) <= total_tof_thresh;
  regs_read_arr(20)(REG_GAPS_TRIGGER_EN_BIT) <= gaps_trigger_en;
  regs_read_arr(20)(REG_REQUIRE_BETA_BIT) <= require_beta;
  regs_read_arr(20)(REG_HIT_THRESH_MSB downto REG_HIT_THRESH_LSB) <= hit_thresh;
  regs_read_arr(21)(REG_TRIG_MASK_A_MSB downto REG_TRIG_MASK_A_LSB) <= trig_mask_a;
  regs_read_arr(22)(REG_TRIG_MASK_B_MSB downto REG_TRIG_MASK_B_LSB) <= trig_mask_b;
  regs_read_arr(23)(REG_TRIGGER_RATE_MSB downto REG_TRIGGER_RATE_LSB) <= trig_rate;
  regs_read_arr(24)(REG_LOST_TRIGGER_RATE_MSB downto REG_LOST_TRIGGER_RATE_LSB) <= lost_trig_rate;
  regs_read_arr(25)(REG_SSL_TRIG_TOP_BOT_EN_BIT) <= ssl_trig_top_bot_en;
  regs_read_arr(25)(REG_SSL_TRIG_TOPEDGE_BOT_EN_BIT) <= ssl_trig_topedge_bot_en;
  regs_read_arr(25)(REG_SSL_TRIG_TOP_BOTEDGE_EN_BIT) <= ssl_trig_top_botedge_en;
  regs_read_arr(25)(REG_SSL_TRIG_TOPMID_BOTMID_EN_BIT) <= ssl_trig_topmid_botmid_en;
  regs_read_arr(26)(REG_LT_LINK_READY0_MSB downto REG_LT_LINK_READY0_LSB) <= lt_link_rdy((0+1)*10-1 downto 0*10);
  regs_read_arr(27)(REG_LT_LINK_READY1_MSB downto REG_LT_LINK_READY1_LSB) <= lt_link_rdy((1+1)*10-1 downto 1*10);
  regs_read_arr(28)(REG_LT_LINK_READY2_MSB downto REG_LT_LINK_READY2_LSB) <= lt_link_rdy((2+1)*10-1 downto 2*10);
  regs_read_arr(29)(REG_LT_LINK_READY3_MSB downto REG_LT_LINK_READY3_LSB) <= lt_link_rdy((3+1)*10-1 downto 3*10);
  regs_read_arr(30)(REG_LT_LINK_READY4_MSB downto REG_LT_LINK_READY4_LSB) <= lt_link_rdy((4+1)*10-1 downto 4*10);
  regs_read_arr(31)(REG_HIT_COUNTERS_LT0_MSB downto REG_HIT_COUNTERS_LT0_LSB) <= hit_count_0;
  regs_read_arr(32)(REG_HIT_COUNTERS_LT1_MSB downto REG_HIT_COUNTERS_LT1_LSB) <= hit_count_1;
  regs_read_arr(33)(REG_HIT_COUNTERS_LT2_MSB downto REG_HIT_COUNTERS_LT2_LSB) <= hit_count_2;
  regs_read_arr(34)(REG_HIT_COUNTERS_LT3_MSB downto REG_HIT_COUNTERS_LT3_LSB) <= hit_count_3;
  regs_read_arr(35)(REG_HIT_COUNTERS_LT4_MSB downto REG_HIT_COUNTERS_LT4_LSB) <= hit_count_4;
  regs_read_arr(36)(REG_HIT_COUNTERS_LT5_MSB downto REG_HIT_COUNTERS_LT5_LSB) <= hit_count_5;
  regs_read_arr(37)(REG_HIT_COUNTERS_LT6_MSB downto REG_HIT_COUNTERS_LT6_LSB) <= hit_count_6;
  regs_read_arr(38)(REG_HIT_COUNTERS_LT7_MSB downto REG_HIT_COUNTERS_LT7_LSB) <= hit_count_7;
  regs_read_arr(39)(REG_HIT_COUNTERS_LT8_MSB downto REG_HIT_COUNTERS_LT8_LSB) <= hit_count_8;
  regs_read_arr(40)(REG_HIT_COUNTERS_LT9_MSB downto REG_HIT_COUNTERS_LT9_LSB) <= hit_count_9;
  regs_read_arr(41)(REG_HIT_COUNTERS_LT10_MSB downto REG_HIT_COUNTERS_LT10_LSB) <= hit_count_10;
  regs_read_arr(42)(REG_HIT_COUNTERS_LT11_MSB downto REG_HIT_COUNTERS_LT11_LSB) <= hit_count_11;
  regs_read_arr(43)(REG_HIT_COUNTERS_LT12_MSB downto REG_HIT_COUNTERS_LT12_LSB) <= hit_count_12;
  regs_read_arr(44)(REG_HIT_COUNTERS_LT13_MSB downto REG_HIT_COUNTERS_LT13_LSB) <= hit_count_13;
  regs_read_arr(45)(REG_HIT_COUNTERS_LT14_MSB downto REG_HIT_COUNTERS_LT14_LSB) <= hit_count_14;
  regs_read_arr(46)(REG_HIT_COUNTERS_LT15_MSB downto REG_HIT_COUNTERS_LT15_LSB) <= hit_count_15;
  regs_read_arr(47)(REG_HIT_COUNTERS_LT16_MSB downto REG_HIT_COUNTERS_LT16_LSB) <= hit_count_16;
  regs_read_arr(48)(REG_HIT_COUNTERS_LT17_MSB downto REG_HIT_COUNTERS_LT17_LSB) <= hit_count_17;
  regs_read_arr(49)(REG_HIT_COUNTERS_LT18_MSB downto REG_HIT_COUNTERS_LT18_LSB) <= hit_count_18;
  regs_read_arr(50)(REG_HIT_COUNTERS_LT19_MSB downto REG_HIT_COUNTERS_LT19_LSB) <= hit_count_19;
  regs_read_arr(51)(REG_HIT_COUNTERS_LT20_MSB downto REG_HIT_COUNTERS_LT20_LSB) <= hit_count_20;
  regs_read_arr(52)(REG_HIT_COUNTERS_LT21_MSB downto REG_HIT_COUNTERS_LT21_LSB) <= hit_count_21;
  regs_read_arr(53)(REG_HIT_COUNTERS_LT22_MSB downto REG_HIT_COUNTERS_LT22_LSB) <= hit_count_22;
  regs_read_arr(54)(REG_HIT_COUNTERS_LT23_MSB downto REG_HIT_COUNTERS_LT23_LSB) <= hit_count_23;
  regs_read_arr(55)(REG_HIT_COUNTERS_LT24_MSB downto REG_HIT_COUNTERS_LT24_LSB) <= hit_count_24;
  regs_read_arr(57)(REG_HIT_COUNTERS_SNAP_BIT) <= cnt_snap;
  regs_read_arr(58)(REG_ETH_RX_BAD_FRAME_CNT_MSB downto REG_ETH_RX_BAD_FRAME_CNT_LSB) <= eth_bad_frame_cnt;
  regs_read_arr(58)(REG_ETH_RX_BAD_FCS_CNT_MSB downto REG_ETH_RX_BAD_FCS_CNT_LSB) <= eth_bad_fcs_cnt;
  regs_read_arr(59)(REG_CHANNEL_MASK_LT0_MSB downto REG_CHANNEL_MASK_LT0_LSB) <= channel_mask(0);
  regs_read_arr(60)(REG_CHANNEL_MASK_LT1_MSB downto REG_CHANNEL_MASK_LT1_LSB) <= channel_mask(1);
  regs_read_arr(61)(REG_CHANNEL_MASK_LT2_MSB downto REG_CHANNEL_MASK_LT2_LSB) <= channel_mask(2);
  regs_read_arr(62)(REG_CHANNEL_MASK_LT3_MSB downto REG_CHANNEL_MASK_LT3_LSB) <= channel_mask(3);
  regs_read_arr(63)(REG_CHANNEL_MASK_LT4_MSB downto REG_CHANNEL_MASK_LT4_LSB) <= channel_mask(4);
  regs_read_arr(64)(REG_CHANNEL_MASK_LT5_MSB downto REG_CHANNEL_MASK_LT5_LSB) <= channel_mask(5);
  regs_read_arr(65)(REG_CHANNEL_MASK_LT6_MSB downto REG_CHANNEL_MASK_LT6_LSB) <= channel_mask(6);
  regs_read_arr(66)(REG_CHANNEL_MASK_LT7_MSB downto REG_CHANNEL_MASK_LT7_LSB) <= channel_mask(7);
  regs_read_arr(67)(REG_CHANNEL_MASK_LT8_MSB downto REG_CHANNEL_MASK_LT8_LSB) <= channel_mask(8);
  regs_read_arr(68)(REG_CHANNEL_MASK_LT9_MSB downto REG_CHANNEL_MASK_LT9_LSB) <= channel_mask(9);
  regs_read_arr(69)(REG_CHANNEL_MASK_LT10_MSB downto REG_CHANNEL_MASK_LT10_LSB) <= channel_mask(10);
  regs_read_arr(70)(REG_CHANNEL_MASK_LT11_MSB downto REG_CHANNEL_MASK_LT11_LSB) <= channel_mask(11);
  regs_read_arr(71)(REG_CHANNEL_MASK_LT12_MSB downto REG_CHANNEL_MASK_LT12_LSB) <= channel_mask(12);
  regs_read_arr(72)(REG_CHANNEL_MASK_LT13_MSB downto REG_CHANNEL_MASK_LT13_LSB) <= channel_mask(13);
  regs_read_arr(73)(REG_CHANNEL_MASK_LT14_MSB downto REG_CHANNEL_MASK_LT14_LSB) <= channel_mask(14);
  regs_read_arr(74)(REG_CHANNEL_MASK_LT15_MSB downto REG_CHANNEL_MASK_LT15_LSB) <= channel_mask(15);
  regs_read_arr(75)(REG_CHANNEL_MASK_LT16_MSB downto REG_CHANNEL_MASK_LT16_LSB) <= channel_mask(16);
  regs_read_arr(76)(REG_CHANNEL_MASK_LT17_MSB downto REG_CHANNEL_MASK_LT17_LSB) <= channel_mask(17);
  regs_read_arr(77)(REG_CHANNEL_MASK_LT18_MSB downto REG_CHANNEL_MASK_LT18_LSB) <= channel_mask(18);
  regs_read_arr(78)(REG_CHANNEL_MASK_LT19_MSB downto REG_CHANNEL_MASK_LT19_LSB) <= channel_mask(19);
  regs_read_arr(79)(REG_CHANNEL_MASK_LT20_MSB downto REG_CHANNEL_MASK_LT20_LSB) <= channel_mask(20);
  regs_read_arr(80)(REG_CHANNEL_MASK_LT21_MSB downto REG_CHANNEL_MASK_LT21_LSB) <= channel_mask(21);
  regs_read_arr(81)(REG_CHANNEL_MASK_LT22_MSB downto REG_CHANNEL_MASK_LT22_LSB) <= channel_mask(22);
  regs_read_arr(82)(REG_CHANNEL_MASK_LT23_MSB downto REG_CHANNEL_MASK_LT23_LSB) <= channel_mask(23);
  regs_read_arr(83)(REG_CHANNEL_MASK_LT24_MSB downto REG_CHANNEL_MASK_LT24_LSB) <= channel_mask(24);
  regs_read_arr(84)(REG_COARSE_DELAYS_LT0_MSB downto REG_COARSE_DELAYS_LT0_LSB) <= coarse_delays(0);
  regs_read_arr(85)(REG_COARSE_DELAYS_LT1_MSB downto REG_COARSE_DELAYS_LT1_LSB) <= coarse_delays(1);
  regs_read_arr(86)(REG_COARSE_DELAYS_LT2_MSB downto REG_COARSE_DELAYS_LT2_LSB) <= coarse_delays(2);
  regs_read_arr(87)(REG_COARSE_DELAYS_LT3_MSB downto REG_COARSE_DELAYS_LT3_LSB) <= coarse_delays(3);
  regs_read_arr(88)(REG_COARSE_DELAYS_LT4_MSB downto REG_COARSE_DELAYS_LT4_LSB) <= coarse_delays(4);
  regs_read_arr(89)(REG_COARSE_DELAYS_LT5_MSB downto REG_COARSE_DELAYS_LT5_LSB) <= coarse_delays(5);
  regs_read_arr(90)(REG_COARSE_DELAYS_LT6_MSB downto REG_COARSE_DELAYS_LT6_LSB) <= coarse_delays(6);
  regs_read_arr(91)(REG_COARSE_DELAYS_LT7_MSB downto REG_COARSE_DELAYS_LT7_LSB) <= coarse_delays(7);
  regs_read_arr(92)(REG_COARSE_DELAYS_LT8_MSB downto REG_COARSE_DELAYS_LT8_LSB) <= coarse_delays(8);
  regs_read_arr(93)(REG_COARSE_DELAYS_LT9_MSB downto REG_COARSE_DELAYS_LT9_LSB) <= coarse_delays(9);
  regs_read_arr(94)(REG_COARSE_DELAYS_LT10_MSB downto REG_COARSE_DELAYS_LT10_LSB) <= coarse_delays(10);
  regs_read_arr(95)(REG_COARSE_DELAYS_LT11_MSB downto REG_COARSE_DELAYS_LT11_LSB) <= coarse_delays(11);
  regs_read_arr(96)(REG_COARSE_DELAYS_LT12_MSB downto REG_COARSE_DELAYS_LT12_LSB) <= coarse_delays(12);
  regs_read_arr(97)(REG_COARSE_DELAYS_LT13_MSB downto REG_COARSE_DELAYS_LT13_LSB) <= coarse_delays(13);
  regs_read_arr(98)(REG_COARSE_DELAYS_LT14_MSB downto REG_COARSE_DELAYS_LT14_LSB) <= coarse_delays(14);
  regs_read_arr(99)(REG_COARSE_DELAYS_LT15_MSB downto REG_COARSE_DELAYS_LT15_LSB) <= coarse_delays(15);
  regs_read_arr(100)(REG_COARSE_DELAYS_LT16_MSB downto REG_COARSE_DELAYS_LT16_LSB) <= coarse_delays(16);
  regs_read_arr(101)(REG_COARSE_DELAYS_LT17_MSB downto REG_COARSE_DELAYS_LT17_LSB) <= coarse_delays(17);
  regs_read_arr(102)(REG_COARSE_DELAYS_LT18_MSB downto REG_COARSE_DELAYS_LT18_LSB) <= coarse_delays(18);
  regs_read_arr(103)(REG_COARSE_DELAYS_LT19_MSB downto REG_COARSE_DELAYS_LT19_LSB) <= coarse_delays(19);
  regs_read_arr(104)(REG_COARSE_DELAYS_LT20_MSB downto REG_COARSE_DELAYS_LT20_LSB) <= coarse_delays(20);
  regs_read_arr(105)(REG_COARSE_DELAYS_LT21_MSB downto REG_COARSE_DELAYS_LT21_LSB) <= coarse_delays(21);
  regs_read_arr(106)(REG_COARSE_DELAYS_LT22_MSB downto REG_COARSE_DELAYS_LT22_LSB) <= coarse_delays(22);
  regs_read_arr(107)(REG_COARSE_DELAYS_LT23_MSB downto REG_COARSE_DELAYS_LT23_LSB) <= coarse_delays(23);
  regs_read_arr(108)(REG_COARSE_DELAYS_LT24_MSB downto REG_COARSE_DELAYS_LT24_LSB) <= coarse_delays(24);
  regs_read_arr(109)(REG_COARSE_DELAYS_LT25_MSB downto REG_COARSE_DELAYS_LT25_LSB) <= coarse_delays(25);
  regs_read_arr(110)(REG_COARSE_DELAYS_LT26_MSB downto REG_COARSE_DELAYS_LT26_LSB) <= coarse_delays(26);
  regs_read_arr(111)(REG_COARSE_DELAYS_LT27_MSB downto REG_COARSE_DELAYS_LT27_LSB) <= coarse_delays(27);
  regs_read_arr(112)(REG_COARSE_DELAYS_LT28_MSB downto REG_COARSE_DELAYS_LT28_LSB) <= coarse_delays(28);
  regs_read_arr(113)(REG_COARSE_DELAYS_LT29_MSB downto REG_COARSE_DELAYS_LT29_LSB) <= coarse_delays(29);
  regs_read_arr(114)(REG_COARSE_DELAYS_LT30_MSB downto REG_COARSE_DELAYS_LT30_LSB) <= coarse_delays(30);
  regs_read_arr(115)(REG_COARSE_DELAYS_LT31_MSB downto REG_COARSE_DELAYS_LT31_LSB) <= coarse_delays(31);
  regs_read_arr(116)(REG_COARSE_DELAYS_LT32_MSB downto REG_COARSE_DELAYS_LT32_LSB) <= coarse_delays(32);
  regs_read_arr(117)(REG_COARSE_DELAYS_LT33_MSB downto REG_COARSE_DELAYS_LT33_LSB) <= coarse_delays(33);
  regs_read_arr(118)(REG_COARSE_DELAYS_LT34_MSB downto REG_COARSE_DELAYS_LT34_LSB) <= coarse_delays(34);
  regs_read_arr(119)(REG_COARSE_DELAYS_LT35_MSB downto REG_COARSE_DELAYS_LT35_LSB) <= coarse_delays(35);
  regs_read_arr(120)(REG_COARSE_DELAYS_LT36_MSB downto REG_COARSE_DELAYS_LT36_LSB) <= coarse_delays(36);
  regs_read_arr(121)(REG_COARSE_DELAYS_LT37_MSB downto REG_COARSE_DELAYS_LT37_LSB) <= coarse_delays(37);
  regs_read_arr(122)(REG_COARSE_DELAYS_LT38_MSB downto REG_COARSE_DELAYS_LT38_LSB) <= coarse_delays(38);
  regs_read_arr(123)(REG_COARSE_DELAYS_LT39_MSB downto REG_COARSE_DELAYS_LT39_LSB) <= coarse_delays(39);
  regs_read_arr(124)(REG_COARSE_DELAYS_LT40_MSB downto REG_COARSE_DELAYS_LT40_LSB) <= coarse_delays(40);
  regs_read_arr(125)(REG_COARSE_DELAYS_LT41_MSB downto REG_COARSE_DELAYS_LT41_LSB) <= coarse_delays(41);
  regs_read_arr(126)(REG_COARSE_DELAYS_LT42_MSB downto REG_COARSE_DELAYS_LT42_LSB) <= coarse_delays(42);
  regs_read_arr(127)(REG_COARSE_DELAYS_LT43_MSB downto REG_COARSE_DELAYS_LT43_LSB) <= coarse_delays(43);
  regs_read_arr(128)(REG_COARSE_DELAYS_LT44_MSB downto REG_COARSE_DELAYS_LT44_LSB) <= coarse_delays(44);
  regs_read_arr(129)(REG_COARSE_DELAYS_LT45_MSB downto REG_COARSE_DELAYS_LT45_LSB) <= coarse_delays(45);
  regs_read_arr(130)(REG_COARSE_DELAYS_LT46_MSB downto REG_COARSE_DELAYS_LT46_LSB) <= coarse_delays(46);
  regs_read_arr(131)(REG_COARSE_DELAYS_LT47_MSB downto REG_COARSE_DELAYS_LT47_LSB) <= coarse_delays(47);
  regs_read_arr(132)(REG_COARSE_DELAYS_LT48_MSB downto REG_COARSE_DELAYS_LT48_LSB) <= coarse_delays(48);
  regs_read_arr(133)(REG_COARSE_DELAYS_LT49_MSB downto REG_COARSE_DELAYS_LT49_LSB) <= coarse_delays(49);
  regs_read_arr(134)(REG_XADC_CALIBRATION_MSB downto REG_XADC_CALIBRATION_LSB) <= calibration;
  regs_read_arr(134)(REG_XADC_VCCPINT_MSB downto REG_XADC_VCCPINT_LSB) <= vccpint;
  regs_read_arr(135)(REG_XADC_VCCPAUX_MSB downto REG_XADC_VCCPAUX_LSB) <= vccpaux;
  regs_read_arr(135)(REG_XADC_VCCODDR_MSB downto REG_XADC_VCCODDR_LSB) <= vccoddr;
  regs_read_arr(136)(REG_XADC_TEMP_MSB downto REG_XADC_TEMP_LSB) <= temp;
  regs_read_arr(136)(REG_XADC_VCCINT_MSB downto REG_XADC_VCCINT_LSB) <= vccint;
  regs_read_arr(137)(REG_XADC_VCCAUX_MSB downto REG_XADC_VCCAUX_LSB) <= vccaux;
  regs_read_arr(137)(REG_XADC_VCCBRAM_MSB downto REG_XADC_VCCBRAM_LSB) <= vccbram;
  regs_read_arr(138)(REG_HOG_GLOBAL_DATE_MSB downto REG_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
  regs_read_arr(139)(REG_HOG_GLOBAL_TIME_MSB downto REG_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
  regs_read_arr(140)(REG_HOG_GLOBAL_VER_MSB downto REG_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
  regs_read_arr(141)(REG_HOG_GLOBAL_SHA_MSB downto REG_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
  regs_read_arr(142)(REG_HOG_TOP_SHA_MSB downto REG_HOG_TOP_SHA_LSB) <= TOP_SHA;
  regs_read_arr(143)(REG_HOG_TOP_VER_MSB downto REG_HOG_TOP_VER_LSB) <= TOP_VER;
  regs_read_arr(144)(REG_HOG_HOG_SHA_MSB downto REG_HOG_HOG_SHA_LSB) <= HOG_SHA;
  regs_read_arr(145)(REG_HOG_HOG_VER_MSB downto REG_HOG_HOG_VER_LSB) <= HOG_VER;

  -- Connect write signals
  loopback <= regs_write_arr(0)(REG_LOOPBACK_MSB downto REG_LOOPBACK_LSB);
  dsi_on_ipb <= regs_write_arr(7)(REG_DSI_ON_MSB downto REG_DSI_ON_LSB);
  trig_gen_rate <= regs_write_arr(9)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB);
  any_trig_en <= regs_write_arr(11)(REG_ANY_TRIG_EN_BIT);
  tiu_emulation_mode <= regs_write_arr(14)(REG_TIU_EMULATION_MODE_BIT);
  tiu_use_aux <= regs_write_arr(14)(REG_TIU_USE_AUX_LINK_BIT);
  tiu_emu_busy_cnt <= regs_write_arr(14)(REG_TIU_EMU_BUSY_CNT_MSB downto REG_TIU_EMU_BUSY_CNT_LSB);
  lt_input_stretch <= regs_write_arr(15)(REG_LT_INPUT_STRETCH_MSB downto REG_LT_INPUT_STRETCH_LSB);
  inner_tof_thresh <= regs_write_arr(20)(REG_INNER_TOF_THRESH_MSB downto REG_INNER_TOF_THRESH_LSB);
  outer_tof_thresh <= regs_write_arr(20)(REG_OUTER_TOF_THRESH_MSB downto REG_OUTER_TOF_THRESH_LSB);
  total_tof_thresh <= regs_write_arr(20)(REG_TOTAL_TOF_THRESH_MSB downto REG_TOTAL_TOF_THRESH_LSB);
  gaps_trigger_en <= regs_write_arr(20)(REG_GAPS_TRIGGER_EN_BIT);
  require_beta <= regs_write_arr(20)(REG_REQUIRE_BETA_BIT);
  hit_thresh <= regs_write_arr(20)(REG_HIT_THRESH_MSB downto REG_HIT_THRESH_LSB);
  trig_mask_a <= regs_write_arr(21)(REG_TRIG_MASK_A_MSB downto REG_TRIG_MASK_A_LSB);
  trig_mask_b <= regs_write_arr(22)(REG_TRIG_MASK_B_MSB downto REG_TRIG_MASK_B_LSB);
  ssl_trig_top_bot_en <= regs_write_arr(25)(REG_SSL_TRIG_TOP_BOT_EN_BIT);
  ssl_trig_topedge_bot_en <= regs_write_arr(25)(REG_SSL_TRIG_TOPEDGE_BOT_EN_BIT);
  ssl_trig_top_botedge_en <= regs_write_arr(25)(REG_SSL_TRIG_TOP_BOTEDGE_EN_BIT);
  ssl_trig_topmid_botmid_en <= regs_write_arr(25)(REG_SSL_TRIG_TOPMID_BOTMID_EN_BIT);
  cnt_snap <= regs_write_arr(57)(REG_HIT_COUNTERS_SNAP_BIT);
  channel_mask(0) <= regs_write_arr(59)(REG_CHANNEL_MASK_LT0_MSB downto REG_CHANNEL_MASK_LT0_LSB);
  channel_mask(1) <= regs_write_arr(60)(REG_CHANNEL_MASK_LT1_MSB downto REG_CHANNEL_MASK_LT1_LSB);
  channel_mask(2) <= regs_write_arr(61)(REG_CHANNEL_MASK_LT2_MSB downto REG_CHANNEL_MASK_LT2_LSB);
  channel_mask(3) <= regs_write_arr(62)(REG_CHANNEL_MASK_LT3_MSB downto REG_CHANNEL_MASK_LT3_LSB);
  channel_mask(4) <= regs_write_arr(63)(REG_CHANNEL_MASK_LT4_MSB downto REG_CHANNEL_MASK_LT4_LSB);
  channel_mask(5) <= regs_write_arr(64)(REG_CHANNEL_MASK_LT5_MSB downto REG_CHANNEL_MASK_LT5_LSB);
  channel_mask(6) <= regs_write_arr(65)(REG_CHANNEL_MASK_LT6_MSB downto REG_CHANNEL_MASK_LT6_LSB);
  channel_mask(7) <= regs_write_arr(66)(REG_CHANNEL_MASK_LT7_MSB downto REG_CHANNEL_MASK_LT7_LSB);
  channel_mask(8) <= regs_write_arr(67)(REG_CHANNEL_MASK_LT8_MSB downto REG_CHANNEL_MASK_LT8_LSB);
  channel_mask(9) <= regs_write_arr(68)(REG_CHANNEL_MASK_LT9_MSB downto REG_CHANNEL_MASK_LT9_LSB);
  channel_mask(10) <= regs_write_arr(69)(REG_CHANNEL_MASK_LT10_MSB downto REG_CHANNEL_MASK_LT10_LSB);
  channel_mask(11) <= regs_write_arr(70)(REG_CHANNEL_MASK_LT11_MSB downto REG_CHANNEL_MASK_LT11_LSB);
  channel_mask(12) <= regs_write_arr(71)(REG_CHANNEL_MASK_LT12_MSB downto REG_CHANNEL_MASK_LT12_LSB);
  channel_mask(13) <= regs_write_arr(72)(REG_CHANNEL_MASK_LT13_MSB downto REG_CHANNEL_MASK_LT13_LSB);
  channel_mask(14) <= regs_write_arr(73)(REG_CHANNEL_MASK_LT14_MSB downto REG_CHANNEL_MASK_LT14_LSB);
  channel_mask(15) <= regs_write_arr(74)(REG_CHANNEL_MASK_LT15_MSB downto REG_CHANNEL_MASK_LT15_LSB);
  channel_mask(16) <= regs_write_arr(75)(REG_CHANNEL_MASK_LT16_MSB downto REG_CHANNEL_MASK_LT16_LSB);
  channel_mask(17) <= regs_write_arr(76)(REG_CHANNEL_MASK_LT17_MSB downto REG_CHANNEL_MASK_LT17_LSB);
  channel_mask(18) <= regs_write_arr(77)(REG_CHANNEL_MASK_LT18_MSB downto REG_CHANNEL_MASK_LT18_LSB);
  channel_mask(19) <= regs_write_arr(78)(REG_CHANNEL_MASK_LT19_MSB downto REG_CHANNEL_MASK_LT19_LSB);
  channel_mask(20) <= regs_write_arr(79)(REG_CHANNEL_MASK_LT20_MSB downto REG_CHANNEL_MASK_LT20_LSB);
  channel_mask(21) <= regs_write_arr(80)(REG_CHANNEL_MASK_LT21_MSB downto REG_CHANNEL_MASK_LT21_LSB);
  channel_mask(22) <= regs_write_arr(81)(REG_CHANNEL_MASK_LT22_MSB downto REG_CHANNEL_MASK_LT22_LSB);
  channel_mask(23) <= regs_write_arr(82)(REG_CHANNEL_MASK_LT23_MSB downto REG_CHANNEL_MASK_LT23_LSB);
  channel_mask(24) <= regs_write_arr(83)(REG_CHANNEL_MASK_LT24_MSB downto REG_CHANNEL_MASK_LT24_LSB);
  coarse_delays(0) <= regs_write_arr(84)(REG_COARSE_DELAYS_LT0_MSB downto REG_COARSE_DELAYS_LT0_LSB);
  coarse_delays(1) <= regs_write_arr(85)(REG_COARSE_DELAYS_LT1_MSB downto REG_COARSE_DELAYS_LT1_LSB);
  coarse_delays(2) <= regs_write_arr(86)(REG_COARSE_DELAYS_LT2_MSB downto REG_COARSE_DELAYS_LT2_LSB);
  coarse_delays(3) <= regs_write_arr(87)(REG_COARSE_DELAYS_LT3_MSB downto REG_COARSE_DELAYS_LT3_LSB);
  coarse_delays(4) <= regs_write_arr(88)(REG_COARSE_DELAYS_LT4_MSB downto REG_COARSE_DELAYS_LT4_LSB);
  coarse_delays(5) <= regs_write_arr(89)(REG_COARSE_DELAYS_LT5_MSB downto REG_COARSE_DELAYS_LT5_LSB);
  coarse_delays(6) <= regs_write_arr(90)(REG_COARSE_DELAYS_LT6_MSB downto REG_COARSE_DELAYS_LT6_LSB);
  coarse_delays(7) <= regs_write_arr(91)(REG_COARSE_DELAYS_LT7_MSB downto REG_COARSE_DELAYS_LT7_LSB);
  coarse_delays(8) <= regs_write_arr(92)(REG_COARSE_DELAYS_LT8_MSB downto REG_COARSE_DELAYS_LT8_LSB);
  coarse_delays(9) <= regs_write_arr(93)(REG_COARSE_DELAYS_LT9_MSB downto REG_COARSE_DELAYS_LT9_LSB);
  coarse_delays(10) <= regs_write_arr(94)(REG_COARSE_DELAYS_LT10_MSB downto REG_COARSE_DELAYS_LT10_LSB);
  coarse_delays(11) <= regs_write_arr(95)(REG_COARSE_DELAYS_LT11_MSB downto REG_COARSE_DELAYS_LT11_LSB);
  coarse_delays(12) <= regs_write_arr(96)(REG_COARSE_DELAYS_LT12_MSB downto REG_COARSE_DELAYS_LT12_LSB);
  coarse_delays(13) <= regs_write_arr(97)(REG_COARSE_DELAYS_LT13_MSB downto REG_COARSE_DELAYS_LT13_LSB);
  coarse_delays(14) <= regs_write_arr(98)(REG_COARSE_DELAYS_LT14_MSB downto REG_COARSE_DELAYS_LT14_LSB);
  coarse_delays(15) <= regs_write_arr(99)(REG_COARSE_DELAYS_LT15_MSB downto REG_COARSE_DELAYS_LT15_LSB);
  coarse_delays(16) <= regs_write_arr(100)(REG_COARSE_DELAYS_LT16_MSB downto REG_COARSE_DELAYS_LT16_LSB);
  coarse_delays(17) <= regs_write_arr(101)(REG_COARSE_DELAYS_LT17_MSB downto REG_COARSE_DELAYS_LT17_LSB);
  coarse_delays(18) <= regs_write_arr(102)(REG_COARSE_DELAYS_LT18_MSB downto REG_COARSE_DELAYS_LT18_LSB);
  coarse_delays(19) <= regs_write_arr(103)(REG_COARSE_DELAYS_LT19_MSB downto REG_COARSE_DELAYS_LT19_LSB);
  coarse_delays(20) <= regs_write_arr(104)(REG_COARSE_DELAYS_LT20_MSB downto REG_COARSE_DELAYS_LT20_LSB);
  coarse_delays(21) <= regs_write_arr(105)(REG_COARSE_DELAYS_LT21_MSB downto REG_COARSE_DELAYS_LT21_LSB);
  coarse_delays(22) <= regs_write_arr(106)(REG_COARSE_DELAYS_LT22_MSB downto REG_COARSE_DELAYS_LT22_LSB);
  coarse_delays(23) <= regs_write_arr(107)(REG_COARSE_DELAYS_LT23_MSB downto REG_COARSE_DELAYS_LT23_LSB);
  coarse_delays(24) <= regs_write_arr(108)(REG_COARSE_DELAYS_LT24_MSB downto REG_COARSE_DELAYS_LT24_LSB);
  coarse_delays(25) <= regs_write_arr(109)(REG_COARSE_DELAYS_LT25_MSB downto REG_COARSE_DELAYS_LT25_LSB);
  coarse_delays(26) <= regs_write_arr(110)(REG_COARSE_DELAYS_LT26_MSB downto REG_COARSE_DELAYS_LT26_LSB);
  coarse_delays(27) <= regs_write_arr(111)(REG_COARSE_DELAYS_LT27_MSB downto REG_COARSE_DELAYS_LT27_LSB);
  coarse_delays(28) <= regs_write_arr(112)(REG_COARSE_DELAYS_LT28_MSB downto REG_COARSE_DELAYS_LT28_LSB);
  coarse_delays(29) <= regs_write_arr(113)(REG_COARSE_DELAYS_LT29_MSB downto REG_COARSE_DELAYS_LT29_LSB);
  coarse_delays(30) <= regs_write_arr(114)(REG_COARSE_DELAYS_LT30_MSB downto REG_COARSE_DELAYS_LT30_LSB);
  coarse_delays(31) <= regs_write_arr(115)(REG_COARSE_DELAYS_LT31_MSB downto REG_COARSE_DELAYS_LT31_LSB);
  coarse_delays(32) <= regs_write_arr(116)(REG_COARSE_DELAYS_LT32_MSB downto REG_COARSE_DELAYS_LT32_LSB);
  coarse_delays(33) <= regs_write_arr(117)(REG_COARSE_DELAYS_LT33_MSB downto REG_COARSE_DELAYS_LT33_LSB);
  coarse_delays(34) <= regs_write_arr(118)(REG_COARSE_DELAYS_LT34_MSB downto REG_COARSE_DELAYS_LT34_LSB);
  coarse_delays(35) <= regs_write_arr(119)(REG_COARSE_DELAYS_LT35_MSB downto REG_COARSE_DELAYS_LT35_LSB);
  coarse_delays(36) <= regs_write_arr(120)(REG_COARSE_DELAYS_LT36_MSB downto REG_COARSE_DELAYS_LT36_LSB);
  coarse_delays(37) <= regs_write_arr(121)(REG_COARSE_DELAYS_LT37_MSB downto REG_COARSE_DELAYS_LT37_LSB);
  coarse_delays(38) <= regs_write_arr(122)(REG_COARSE_DELAYS_LT38_MSB downto REG_COARSE_DELAYS_LT38_LSB);
  coarse_delays(39) <= regs_write_arr(123)(REG_COARSE_DELAYS_LT39_MSB downto REG_COARSE_DELAYS_LT39_LSB);
  coarse_delays(40) <= regs_write_arr(124)(REG_COARSE_DELAYS_LT40_MSB downto REG_COARSE_DELAYS_LT40_LSB);
  coarse_delays(41) <= regs_write_arr(125)(REG_COARSE_DELAYS_LT41_MSB downto REG_COARSE_DELAYS_LT41_LSB);
  coarse_delays(42) <= regs_write_arr(126)(REG_COARSE_DELAYS_LT42_MSB downto REG_COARSE_DELAYS_LT42_LSB);
  coarse_delays(43) <= regs_write_arr(127)(REG_COARSE_DELAYS_LT43_MSB downto REG_COARSE_DELAYS_LT43_LSB);
  coarse_delays(44) <= regs_write_arr(128)(REG_COARSE_DELAYS_LT44_MSB downto REG_COARSE_DELAYS_LT44_LSB);
  coarse_delays(45) <= regs_write_arr(129)(REG_COARSE_DELAYS_LT45_MSB downto REG_COARSE_DELAYS_LT45_LSB);
  coarse_delays(46) <= regs_write_arr(130)(REG_COARSE_DELAYS_LT46_MSB downto REG_COARSE_DELAYS_LT46_LSB);
  coarse_delays(47) <= regs_write_arr(131)(REG_COARSE_DELAYS_LT47_MSB downto REG_COARSE_DELAYS_LT47_LSB);
  coarse_delays(48) <= regs_write_arr(132)(REG_COARSE_DELAYS_LT48_MSB downto REG_COARSE_DELAYS_LT48_LSB);
  coarse_delays(49) <= regs_write_arr(133)(REG_COARSE_DELAYS_LT49_MSB downto REG_COARSE_DELAYS_LT49_LSB);

  -- Connect write pulse signals
  trigger_ipb <= regs_write_pulse_arr(8);
  rb_resync <= regs_write_pulse_arr(10);
  event_cnt_reset <= regs_write_pulse_arr(12);
  daq_reset <= regs_write_pulse_arr(16);
  hit_cnt_reset <= regs_write_pulse_arr(56);

  -- Connect write done signals

  -- Connect read pulse signals
  daq_rd_en <= regs_read_pulse_arr(17);
  daq_pkt_size_rd_en <= regs_read_pulse_arr(19);

  -- Connect counter instances

  COUNTER_HIT_COUNTERS_LT0 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(0),
      snap_i    => cnt_snap,
      count_o   => hit_count_0
  );


  COUNTER_HIT_COUNTERS_LT1 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(1),
      snap_i    => cnt_snap,
      count_o   => hit_count_1
  );


  COUNTER_HIT_COUNTERS_LT2 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(2),
      snap_i    => cnt_snap,
      count_o   => hit_count_2
  );


  COUNTER_HIT_COUNTERS_LT3 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(3),
      snap_i    => cnt_snap,
      count_o   => hit_count_3
  );


  COUNTER_HIT_COUNTERS_LT4 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(4),
      snap_i    => cnt_snap,
      count_o   => hit_count_4
  );


  COUNTER_HIT_COUNTERS_LT5 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(5),
      snap_i    => cnt_snap,
      count_o   => hit_count_5
  );


  COUNTER_HIT_COUNTERS_LT6 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(6),
      snap_i    => cnt_snap,
      count_o   => hit_count_6
  );


  COUNTER_HIT_COUNTERS_LT7 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(7),
      snap_i    => cnt_snap,
      count_o   => hit_count_7
  );


  COUNTER_HIT_COUNTERS_LT8 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(8),
      snap_i    => cnt_snap,
      count_o   => hit_count_8
  );


  COUNTER_HIT_COUNTERS_LT9 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(9),
      snap_i    => cnt_snap,
      count_o   => hit_count_9
  );


  COUNTER_HIT_COUNTERS_LT10 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(10),
      snap_i    => cnt_snap,
      count_o   => hit_count_10
  );


  COUNTER_HIT_COUNTERS_LT11 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(11),
      snap_i    => cnt_snap,
      count_o   => hit_count_11
  );


  COUNTER_HIT_COUNTERS_LT12 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(12),
      snap_i    => cnt_snap,
      count_o   => hit_count_12
  );


  COUNTER_HIT_COUNTERS_LT13 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(13),
      snap_i    => cnt_snap,
      count_o   => hit_count_13
  );


  COUNTER_HIT_COUNTERS_LT14 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(14),
      snap_i    => cnt_snap,
      count_o   => hit_count_14
  );


  COUNTER_HIT_COUNTERS_LT15 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(15),
      snap_i    => cnt_snap,
      count_o   => hit_count_15
  );


  COUNTER_HIT_COUNTERS_LT16 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(16),
      snap_i    => cnt_snap,
      count_o   => hit_count_16
  );


  COUNTER_HIT_COUNTERS_LT17 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(17),
      snap_i    => cnt_snap,
      count_o   => hit_count_17
  );


  COUNTER_HIT_COUNTERS_LT18 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(18),
      snap_i    => cnt_snap,
      count_o   => hit_count_18
  );


  COUNTER_HIT_COUNTERS_LT19 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(19),
      snap_i    => cnt_snap,
      count_o   => hit_count_19
  );


  COUNTER_HIT_COUNTERS_LT20 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(20),
      snap_i    => cnt_snap,
      count_o   => hit_count_20
  );


  COUNTER_HIT_COUNTERS_LT21 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(21),
      snap_i    => cnt_snap,
      count_o   => hit_count_21
  );


  COUNTER_HIT_COUNTERS_LT22 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(22),
      snap_i    => cnt_snap,
      count_o   => hit_count_22
  );


  COUNTER_HIT_COUNTERS_LT23 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(23),
      snap_i    => cnt_snap,
      count_o   => hit_count_23
  );


  COUNTER_HIT_COUNTERS_LT24 : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 24
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset or hit_cnt_reset,
      en_i      => ltb_hit(24),
      snap_i    => cnt_snap,
      count_o   => hit_count_24
  );


  COUNTER_ETH_RX_BAD_FRAME_CNT : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => eth_bad_frame,
      snap_i    => '1',
      count_o   => eth_bad_frame_cnt
  );


  COUNTER_ETH_RX_BAD_FCS_CNT : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => ipb_reset,
      en_i      => eth_bad_fcs,
      snap_i    => '1',
      count_o   => eth_bad_fcs_cnt
  );


  -- Connect rate instances

  -- Connect read ready signals
    regs_read_ready_arr(17) <= daq_valid_xfifo;
    regs_read_ready_arr(19) <= daq_pkt_size_rd_done;

  -- Defaults
  regs_defaults(0)(REG_LOOPBACK_MSB downto REG_LOOPBACK_LSB) <= REG_LOOPBACK_DEFAULT;
  regs_defaults(7)(REG_DSI_ON_MSB downto REG_DSI_ON_LSB) <= REG_DSI_ON_DEFAULT;
  regs_defaults(9)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= REG_TRIG_GEN_RATE_DEFAULT;
  regs_defaults(11)(REG_ANY_TRIG_EN_BIT) <= REG_ANY_TRIG_EN_DEFAULT;
  regs_defaults(14)(REG_TIU_EMULATION_MODE_BIT) <= REG_TIU_EMULATION_MODE_DEFAULT;
  regs_defaults(14)(REG_TIU_USE_AUX_LINK_BIT) <= REG_TIU_USE_AUX_LINK_DEFAULT;
  regs_defaults(14)(REG_TIU_EMU_BUSY_CNT_MSB downto REG_TIU_EMU_BUSY_CNT_LSB) <= REG_TIU_EMU_BUSY_CNT_DEFAULT;
  regs_defaults(15)(REG_LT_INPUT_STRETCH_MSB downto REG_LT_INPUT_STRETCH_LSB) <= REG_LT_INPUT_STRETCH_DEFAULT;
  regs_defaults(20)(REG_INNER_TOF_THRESH_MSB downto REG_INNER_TOF_THRESH_LSB) <= REG_INNER_TOF_THRESH_DEFAULT;
  regs_defaults(20)(REG_OUTER_TOF_THRESH_MSB downto REG_OUTER_TOF_THRESH_LSB) <= REG_OUTER_TOF_THRESH_DEFAULT;
  regs_defaults(20)(REG_TOTAL_TOF_THRESH_MSB downto REG_TOTAL_TOF_THRESH_LSB) <= REG_TOTAL_TOF_THRESH_DEFAULT;
  regs_defaults(20)(REG_GAPS_TRIGGER_EN_BIT) <= REG_GAPS_TRIGGER_EN_DEFAULT;
  regs_defaults(20)(REG_REQUIRE_BETA_BIT) <= REG_REQUIRE_BETA_DEFAULT;
  regs_defaults(20)(REG_HIT_THRESH_MSB downto REG_HIT_THRESH_LSB) <= REG_HIT_THRESH_DEFAULT;
  regs_defaults(21)(REG_TRIG_MASK_A_MSB downto REG_TRIG_MASK_A_LSB) <= REG_TRIG_MASK_A_DEFAULT;
  regs_defaults(22)(REG_TRIG_MASK_B_MSB downto REG_TRIG_MASK_B_LSB) <= REG_TRIG_MASK_B_DEFAULT;
  regs_defaults(25)(REG_SSL_TRIG_TOP_BOT_EN_BIT) <= REG_SSL_TRIG_TOP_BOT_EN_DEFAULT;
  regs_defaults(25)(REG_SSL_TRIG_TOPEDGE_BOT_EN_BIT) <= REG_SSL_TRIG_TOPEDGE_BOT_EN_DEFAULT;
  regs_defaults(25)(REG_SSL_TRIG_TOP_BOTEDGE_EN_BIT) <= REG_SSL_TRIG_TOP_BOTEDGE_EN_DEFAULT;
  regs_defaults(25)(REG_SSL_TRIG_TOPMID_BOTMID_EN_BIT) <= REG_SSL_TRIG_TOPMID_BOTMID_EN_DEFAULT;
  regs_defaults(57)(REG_HIT_COUNTERS_SNAP_BIT) <= REG_HIT_COUNTERS_SNAP_DEFAULT;
  regs_defaults(59)(REG_CHANNEL_MASK_LT0_MSB downto REG_CHANNEL_MASK_LT0_LSB) <= REG_CHANNEL_MASK_LT0_DEFAULT;
  regs_defaults(60)(REG_CHANNEL_MASK_LT1_MSB downto REG_CHANNEL_MASK_LT1_LSB) <= REG_CHANNEL_MASK_LT1_DEFAULT;
  regs_defaults(61)(REG_CHANNEL_MASK_LT2_MSB downto REG_CHANNEL_MASK_LT2_LSB) <= REG_CHANNEL_MASK_LT2_DEFAULT;
  regs_defaults(62)(REG_CHANNEL_MASK_LT3_MSB downto REG_CHANNEL_MASK_LT3_LSB) <= REG_CHANNEL_MASK_LT3_DEFAULT;
  regs_defaults(63)(REG_CHANNEL_MASK_LT4_MSB downto REG_CHANNEL_MASK_LT4_LSB) <= REG_CHANNEL_MASK_LT4_DEFAULT;
  regs_defaults(64)(REG_CHANNEL_MASK_LT5_MSB downto REG_CHANNEL_MASK_LT5_LSB) <= REG_CHANNEL_MASK_LT5_DEFAULT;
  regs_defaults(65)(REG_CHANNEL_MASK_LT6_MSB downto REG_CHANNEL_MASK_LT6_LSB) <= REG_CHANNEL_MASK_LT6_DEFAULT;
  regs_defaults(66)(REG_CHANNEL_MASK_LT7_MSB downto REG_CHANNEL_MASK_LT7_LSB) <= REG_CHANNEL_MASK_LT7_DEFAULT;
  regs_defaults(67)(REG_CHANNEL_MASK_LT8_MSB downto REG_CHANNEL_MASK_LT8_LSB) <= REG_CHANNEL_MASK_LT8_DEFAULT;
  regs_defaults(68)(REG_CHANNEL_MASK_LT9_MSB downto REG_CHANNEL_MASK_LT9_LSB) <= REG_CHANNEL_MASK_LT9_DEFAULT;
  regs_defaults(69)(REG_CHANNEL_MASK_LT10_MSB downto REG_CHANNEL_MASK_LT10_LSB) <= REG_CHANNEL_MASK_LT10_DEFAULT;
  regs_defaults(70)(REG_CHANNEL_MASK_LT11_MSB downto REG_CHANNEL_MASK_LT11_LSB) <= REG_CHANNEL_MASK_LT11_DEFAULT;
  regs_defaults(71)(REG_CHANNEL_MASK_LT12_MSB downto REG_CHANNEL_MASK_LT12_LSB) <= REG_CHANNEL_MASK_LT12_DEFAULT;
  regs_defaults(72)(REG_CHANNEL_MASK_LT13_MSB downto REG_CHANNEL_MASK_LT13_LSB) <= REG_CHANNEL_MASK_LT13_DEFAULT;
  regs_defaults(73)(REG_CHANNEL_MASK_LT14_MSB downto REG_CHANNEL_MASK_LT14_LSB) <= REG_CHANNEL_MASK_LT14_DEFAULT;
  regs_defaults(74)(REG_CHANNEL_MASK_LT15_MSB downto REG_CHANNEL_MASK_LT15_LSB) <= REG_CHANNEL_MASK_LT15_DEFAULT;
  regs_defaults(75)(REG_CHANNEL_MASK_LT16_MSB downto REG_CHANNEL_MASK_LT16_LSB) <= REG_CHANNEL_MASK_LT16_DEFAULT;
  regs_defaults(76)(REG_CHANNEL_MASK_LT17_MSB downto REG_CHANNEL_MASK_LT17_LSB) <= REG_CHANNEL_MASK_LT17_DEFAULT;
  regs_defaults(77)(REG_CHANNEL_MASK_LT18_MSB downto REG_CHANNEL_MASK_LT18_LSB) <= REG_CHANNEL_MASK_LT18_DEFAULT;
  regs_defaults(78)(REG_CHANNEL_MASK_LT19_MSB downto REG_CHANNEL_MASK_LT19_LSB) <= REG_CHANNEL_MASK_LT19_DEFAULT;
  regs_defaults(79)(REG_CHANNEL_MASK_LT20_MSB downto REG_CHANNEL_MASK_LT20_LSB) <= REG_CHANNEL_MASK_LT20_DEFAULT;
  regs_defaults(80)(REG_CHANNEL_MASK_LT21_MSB downto REG_CHANNEL_MASK_LT21_LSB) <= REG_CHANNEL_MASK_LT21_DEFAULT;
  regs_defaults(81)(REG_CHANNEL_MASK_LT22_MSB downto REG_CHANNEL_MASK_LT22_LSB) <= REG_CHANNEL_MASK_LT22_DEFAULT;
  regs_defaults(82)(REG_CHANNEL_MASK_LT23_MSB downto REG_CHANNEL_MASK_LT23_LSB) <= REG_CHANNEL_MASK_LT23_DEFAULT;
  regs_defaults(83)(REG_CHANNEL_MASK_LT24_MSB downto REG_CHANNEL_MASK_LT24_LSB) <= REG_CHANNEL_MASK_LT24_DEFAULT;
  regs_defaults(84)(REG_COARSE_DELAYS_LT0_MSB downto REG_COARSE_DELAYS_LT0_LSB) <= REG_COARSE_DELAYS_LT0_DEFAULT;
  regs_defaults(85)(REG_COARSE_DELAYS_LT1_MSB downto REG_COARSE_DELAYS_LT1_LSB) <= REG_COARSE_DELAYS_LT1_DEFAULT;
  regs_defaults(86)(REG_COARSE_DELAYS_LT2_MSB downto REG_COARSE_DELAYS_LT2_LSB) <= REG_COARSE_DELAYS_LT2_DEFAULT;
  regs_defaults(87)(REG_COARSE_DELAYS_LT3_MSB downto REG_COARSE_DELAYS_LT3_LSB) <= REG_COARSE_DELAYS_LT3_DEFAULT;
  regs_defaults(88)(REG_COARSE_DELAYS_LT4_MSB downto REG_COARSE_DELAYS_LT4_LSB) <= REG_COARSE_DELAYS_LT4_DEFAULT;
  regs_defaults(89)(REG_COARSE_DELAYS_LT5_MSB downto REG_COARSE_DELAYS_LT5_LSB) <= REG_COARSE_DELAYS_LT5_DEFAULT;
  regs_defaults(90)(REG_COARSE_DELAYS_LT6_MSB downto REG_COARSE_DELAYS_LT6_LSB) <= REG_COARSE_DELAYS_LT6_DEFAULT;
  regs_defaults(91)(REG_COARSE_DELAYS_LT7_MSB downto REG_COARSE_DELAYS_LT7_LSB) <= REG_COARSE_DELAYS_LT7_DEFAULT;
  regs_defaults(92)(REG_COARSE_DELAYS_LT8_MSB downto REG_COARSE_DELAYS_LT8_LSB) <= REG_COARSE_DELAYS_LT8_DEFAULT;
  regs_defaults(93)(REG_COARSE_DELAYS_LT9_MSB downto REG_COARSE_DELAYS_LT9_LSB) <= REG_COARSE_DELAYS_LT9_DEFAULT;
  regs_defaults(94)(REG_COARSE_DELAYS_LT10_MSB downto REG_COARSE_DELAYS_LT10_LSB) <= REG_COARSE_DELAYS_LT10_DEFAULT;
  regs_defaults(95)(REG_COARSE_DELAYS_LT11_MSB downto REG_COARSE_DELAYS_LT11_LSB) <= REG_COARSE_DELAYS_LT11_DEFAULT;
  regs_defaults(96)(REG_COARSE_DELAYS_LT12_MSB downto REG_COARSE_DELAYS_LT12_LSB) <= REG_COARSE_DELAYS_LT12_DEFAULT;
  regs_defaults(97)(REG_COARSE_DELAYS_LT13_MSB downto REG_COARSE_DELAYS_LT13_LSB) <= REG_COARSE_DELAYS_LT13_DEFAULT;
  regs_defaults(98)(REG_COARSE_DELAYS_LT14_MSB downto REG_COARSE_DELAYS_LT14_LSB) <= REG_COARSE_DELAYS_LT14_DEFAULT;
  regs_defaults(99)(REG_COARSE_DELAYS_LT15_MSB downto REG_COARSE_DELAYS_LT15_LSB) <= REG_COARSE_DELAYS_LT15_DEFAULT;
  regs_defaults(100)(REG_COARSE_DELAYS_LT16_MSB downto REG_COARSE_DELAYS_LT16_LSB) <= REG_COARSE_DELAYS_LT16_DEFAULT;
  regs_defaults(101)(REG_COARSE_DELAYS_LT17_MSB downto REG_COARSE_DELAYS_LT17_LSB) <= REG_COARSE_DELAYS_LT17_DEFAULT;
  regs_defaults(102)(REG_COARSE_DELAYS_LT18_MSB downto REG_COARSE_DELAYS_LT18_LSB) <= REG_COARSE_DELAYS_LT18_DEFAULT;
  regs_defaults(103)(REG_COARSE_DELAYS_LT19_MSB downto REG_COARSE_DELAYS_LT19_LSB) <= REG_COARSE_DELAYS_LT19_DEFAULT;
  regs_defaults(104)(REG_COARSE_DELAYS_LT20_MSB downto REG_COARSE_DELAYS_LT20_LSB) <= REG_COARSE_DELAYS_LT20_DEFAULT;
  regs_defaults(105)(REG_COARSE_DELAYS_LT21_MSB downto REG_COARSE_DELAYS_LT21_LSB) <= REG_COARSE_DELAYS_LT21_DEFAULT;
  regs_defaults(106)(REG_COARSE_DELAYS_LT22_MSB downto REG_COARSE_DELAYS_LT22_LSB) <= REG_COARSE_DELAYS_LT22_DEFAULT;
  regs_defaults(107)(REG_COARSE_DELAYS_LT23_MSB downto REG_COARSE_DELAYS_LT23_LSB) <= REG_COARSE_DELAYS_LT23_DEFAULT;
  regs_defaults(108)(REG_COARSE_DELAYS_LT24_MSB downto REG_COARSE_DELAYS_LT24_LSB) <= REG_COARSE_DELAYS_LT24_DEFAULT;
  regs_defaults(109)(REG_COARSE_DELAYS_LT25_MSB downto REG_COARSE_DELAYS_LT25_LSB) <= REG_COARSE_DELAYS_LT25_DEFAULT;
  regs_defaults(110)(REG_COARSE_DELAYS_LT26_MSB downto REG_COARSE_DELAYS_LT26_LSB) <= REG_COARSE_DELAYS_LT26_DEFAULT;
  regs_defaults(111)(REG_COARSE_DELAYS_LT27_MSB downto REG_COARSE_DELAYS_LT27_LSB) <= REG_COARSE_DELAYS_LT27_DEFAULT;
  regs_defaults(112)(REG_COARSE_DELAYS_LT28_MSB downto REG_COARSE_DELAYS_LT28_LSB) <= REG_COARSE_DELAYS_LT28_DEFAULT;
  regs_defaults(113)(REG_COARSE_DELAYS_LT29_MSB downto REG_COARSE_DELAYS_LT29_LSB) <= REG_COARSE_DELAYS_LT29_DEFAULT;
  regs_defaults(114)(REG_COARSE_DELAYS_LT30_MSB downto REG_COARSE_DELAYS_LT30_LSB) <= REG_COARSE_DELAYS_LT30_DEFAULT;
  regs_defaults(115)(REG_COARSE_DELAYS_LT31_MSB downto REG_COARSE_DELAYS_LT31_LSB) <= REG_COARSE_DELAYS_LT31_DEFAULT;
  regs_defaults(116)(REG_COARSE_DELAYS_LT32_MSB downto REG_COARSE_DELAYS_LT32_LSB) <= REG_COARSE_DELAYS_LT32_DEFAULT;
  regs_defaults(117)(REG_COARSE_DELAYS_LT33_MSB downto REG_COARSE_DELAYS_LT33_LSB) <= REG_COARSE_DELAYS_LT33_DEFAULT;
  regs_defaults(118)(REG_COARSE_DELAYS_LT34_MSB downto REG_COARSE_DELAYS_LT34_LSB) <= REG_COARSE_DELAYS_LT34_DEFAULT;
  regs_defaults(119)(REG_COARSE_DELAYS_LT35_MSB downto REG_COARSE_DELAYS_LT35_LSB) <= REG_COARSE_DELAYS_LT35_DEFAULT;
  regs_defaults(120)(REG_COARSE_DELAYS_LT36_MSB downto REG_COARSE_DELAYS_LT36_LSB) <= REG_COARSE_DELAYS_LT36_DEFAULT;
  regs_defaults(121)(REG_COARSE_DELAYS_LT37_MSB downto REG_COARSE_DELAYS_LT37_LSB) <= REG_COARSE_DELAYS_LT37_DEFAULT;
  regs_defaults(122)(REG_COARSE_DELAYS_LT38_MSB downto REG_COARSE_DELAYS_LT38_LSB) <= REG_COARSE_DELAYS_LT38_DEFAULT;
  regs_defaults(123)(REG_COARSE_DELAYS_LT39_MSB downto REG_COARSE_DELAYS_LT39_LSB) <= REG_COARSE_DELAYS_LT39_DEFAULT;
  regs_defaults(124)(REG_COARSE_DELAYS_LT40_MSB downto REG_COARSE_DELAYS_LT40_LSB) <= REG_COARSE_DELAYS_LT40_DEFAULT;
  regs_defaults(125)(REG_COARSE_DELAYS_LT41_MSB downto REG_COARSE_DELAYS_LT41_LSB) <= REG_COARSE_DELAYS_LT41_DEFAULT;
  regs_defaults(126)(REG_COARSE_DELAYS_LT42_MSB downto REG_COARSE_DELAYS_LT42_LSB) <= REG_COARSE_DELAYS_LT42_DEFAULT;
  regs_defaults(127)(REG_COARSE_DELAYS_LT43_MSB downto REG_COARSE_DELAYS_LT43_LSB) <= REG_COARSE_DELAYS_LT43_DEFAULT;
  regs_defaults(128)(REG_COARSE_DELAYS_LT44_MSB downto REG_COARSE_DELAYS_LT44_LSB) <= REG_COARSE_DELAYS_LT44_DEFAULT;
  regs_defaults(129)(REG_COARSE_DELAYS_LT45_MSB downto REG_COARSE_DELAYS_LT45_LSB) <= REG_COARSE_DELAYS_LT45_DEFAULT;
  regs_defaults(130)(REG_COARSE_DELAYS_LT46_MSB downto REG_COARSE_DELAYS_LT46_LSB) <= REG_COARSE_DELAYS_LT46_DEFAULT;
  regs_defaults(131)(REG_COARSE_DELAYS_LT47_MSB downto REG_COARSE_DELAYS_LT47_LSB) <= REG_COARSE_DELAYS_LT47_DEFAULT;
  regs_defaults(132)(REG_COARSE_DELAYS_LT48_MSB downto REG_COARSE_DELAYS_LT48_LSB) <= REG_COARSE_DELAYS_LT48_DEFAULT;
  regs_defaults(133)(REG_COARSE_DELAYS_LT49_MSB downto REG_COARSE_DELAYS_LT49_LSB) <= REG_COARSE_DELAYS_LT49_DEFAULT;

  -- Define writable regs
  regs_writable_arr(0) <= '1';
  regs_writable_arr(7) <= '1';
  regs_writable_arr(9) <= '1';
  regs_writable_arr(11) <= '1';
  regs_writable_arr(14) <= '1';
  regs_writable_arr(15) <= '1';
  regs_writable_arr(20) <= '1';
  regs_writable_arr(21) <= '1';
  regs_writable_arr(22) <= '1';
  regs_writable_arr(25) <= '1';
  regs_writable_arr(57) <= '1';
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
  regs_writable_arr(131) <= '1';
  regs_writable_arr(132) <= '1';
  regs_writable_arr(133) <= '1';

--==== Registers end ============================================================================
end structural;
