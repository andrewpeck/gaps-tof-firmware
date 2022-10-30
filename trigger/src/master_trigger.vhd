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

    LOOPBACK_MODE : boolean := false;

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

  signal fine_delays : lt_fine_delays_array_t
    := (others => (others => '0'));
  signal coarse_delays : lt_coarse_delays_array_t
    := (others => (others => '0'));
  signal posnegs : lt_posnegs_array_t := (others => '0');

  signal posnegs_dsi0 : std_logic_vector(75/5 -1 downto 0);
  signal posnegs_dsi1 : std_logic_vector(75/5 -1 downto 0);
  signal posnegs_dsi2 : std_logic_vector(75/5 -1 downto 0);
  signal posnegs_dsi3 : std_logic_vector(75/5 -1 downto 0);
  signal posnegs_dsi4 : std_logic_vector(75/5 -1 downto 0);

  signal pulse_stretch : std_logic_vector (3 downto 0)
    := (others => '0');

  signal dsi_link_en : std_logic_vector(lt_data_i_p'range);

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

  signal fb_clk, fb_clk_i : std_logic_vector (fb_clk_p'range);
  signal fb_clock_rates   : t_std32_array(fb_clk_p'range);
  signal fb_clk_ok        : std_logic_vector (fb_clk_p'range);
  constant FB_CLK_FREQ    : integer := 20_000_000;
  constant FB_CLK_TOL     : integer := 10_000;

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

  sys_clk_bufg : BUFG
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
        clk_a_freq => 100000000
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

  dsi_link_en <= repeat(fb_clk_ok(4), NUM_LT_INPUTS/NUM_DSI) &
                 repeat(fb_clk_ok(3), NUM_LT_INPUTS/NUM_DSI) &
                 repeat(fb_clk_ok(2), NUM_LT_INPUTS/NUM_DSI) &
                 repeat(fb_clk_ok(1), NUM_LT_INPUTS/NUM_DSI) &
                 repeat(fb_clk_ok(0), NUM_LT_INPUTS/NUM_DSI);

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

        link_en  => dsi_link_en,

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

      reset => reset,

      -- hits from input stage (20x16 array of hits)
      hits_i => hits_masked,

      busy_i => tiu_busy,

      single_hit_en_i => '1',
      bool_trg_en_i   => '1',
      force_trigger_i => trigger_ipb or trig_gen,

      event_cnt_o => event_cnt,

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
  -- trigger tx
  --------------------------------------------------------------------------------
  --
  -- takes in triggers, returns a serialized packet to send to the readout board
  --
  --------------------------------------------------------------------------------

  noloop_t : if (not LOOPBACK_MODE) generate

    -- extend the trigger pulses by a few clocks for the fast to slow clock transition
    trg_tx_gen : for I in 0 to NUM_RBS-1 generate
      signal trg_extend : std_logic_vector (7 downto 0) := (others => '0');
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

      trg_tx_inst : entity work.trg_tx
        generic map (
          EVENTCNTB => EVENTCNTB,
          MASKCNTB  => NUM_RB_CHANNELS
          )
        port map (
          clock       => clk25,
          reset       => reset,
          serial_o    => rb_data_o(I),
          trg_i       => or_reduce(trg_extend),
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

    tiu_tx_inst : entity work.tiu_tx
      generic map (
        EVENTCNTB => 32,
        DIV       => 100
        )
      port map (
        clock       => clock,
        reset       => reset,
        serial_o    => tiu_serial_o,
        trg_i       => global_trigger,
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
        THRE => open,
        THRL => '0',
        TRE  => open
        );

    -- on the falling edge of the tiu signal, latch the timecode

    process (clock) is
    begin
      if (rising_edge(clock)) then

        tiu_timecode_sr(0) <= tiu_timecode_i;

        for I in 1 to tiu_timecode_sr'length-1 loop
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
  regs_addresses(91)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"74";
  regs_addresses(92)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"75";
  regs_addresses(93)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"76";
  regs_addresses(94)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"77";
  regs_addresses(95)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"78";
  regs_addresses(96)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"79";
  regs_addresses(97)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7a";
  regs_addresses(98)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7b";
  regs_addresses(99)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7c";
  regs_addresses(100)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7d";
  regs_addresses(101)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7e";
  regs_addresses(102)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"7f";
  regs_addresses(103)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"80";
  regs_addresses(104)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"81";
  regs_addresses(105)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"82";
  regs_addresses(106)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"83";
  regs_addresses(107)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"84";
  regs_addresses(108)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"85";
  regs_addresses(109)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"86";
  regs_addresses(110)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"87";
  regs_addresses(111)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"88";
  regs_addresses(112)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"89";
  regs_addresses(113)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8a";
  regs_addresses(114)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8b";
  regs_addresses(115)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8c";
  regs_addresses(116)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8d";
  regs_addresses(117)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8e";
  regs_addresses(118)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"8f";
  regs_addresses(119)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"90";
  regs_addresses(120)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"91";
  regs_addresses(121)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"92";
  regs_addresses(122)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"93";
  regs_addresses(123)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"94";
  regs_addresses(124)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"95";
  regs_addresses(125)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"96";
  regs_addresses(126)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"97";
  regs_addresses(127)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"98";
  regs_addresses(128)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"99";
  regs_addresses(129)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9a";
  regs_addresses(130)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9b";
  regs_addresses(131)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9c";
  regs_addresses(132)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9d";
  regs_addresses(133)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9e";
  regs_addresses(134)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"9f";
  regs_addresses(135)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a0";
  regs_addresses(136)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a1";
  regs_addresses(137)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a2";
  regs_addresses(138)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a3";
  regs_addresses(139)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a4";
  regs_addresses(140)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a5";
  regs_addresses(141)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a6";
  regs_addresses(142)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a7";
  regs_addresses(143)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a8";
  regs_addresses(144)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"a9";
  regs_addresses(145)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"aa";
  regs_addresses(146)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c0";
  regs_addresses(147)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c1";
  regs_addresses(148)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c2";
  regs_addresses(149)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c3";
  regs_addresses(150)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c4";
  regs_addresses(151)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c5";
  regs_addresses(152)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c6";
  regs_addresses(153)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c7";
  regs_addresses(154)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c8";
  regs_addresses(155)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"c9";
  regs_addresses(156)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ca";
  regs_addresses(157)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cb";
  regs_addresses(158)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cc";
  regs_addresses(159)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cd";
  regs_addresses(160)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ce";
  regs_addresses(161)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"cf";
  regs_addresses(162)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d0";
  regs_addresses(163)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d1";
  regs_addresses(164)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d2";
  regs_addresses(165)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d3";
  regs_addresses(166)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d4";
  regs_addresses(167)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d5";
  regs_addresses(168)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d6";
  regs_addresses(169)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d7";
  regs_addresses(170)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d8";
  regs_addresses(171)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"d9";
  regs_addresses(172)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"da";
  regs_addresses(173)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"db";
  regs_addresses(174)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"dc";
  regs_addresses(175)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"dd";
  regs_addresses(176)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"de";
  regs_addresses(177)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"df";
  regs_addresses(178)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e0";
  regs_addresses(179)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e1";
  regs_addresses(180)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e2";
  regs_addresses(181)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e3";
  regs_addresses(182)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e4";
  regs_addresses(183)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e5";
  regs_addresses(184)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e6";
  regs_addresses(185)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e7";
  regs_addresses(186)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e8";
  regs_addresses(187)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"e9";
  regs_addresses(188)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ea";
  regs_addresses(189)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"eb";
  regs_addresses(190)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ec";
  regs_addresses(191)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ed";
  regs_addresses(192)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ee";
  regs_addresses(193)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ef";
  regs_addresses(194)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f0";
  regs_addresses(195)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f1";
  regs_addresses(196)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f2";
  regs_addresses(197)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f3";
  regs_addresses(198)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f4";
  regs_addresses(199)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f5";
  regs_addresses(200)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f6";
  regs_addresses(201)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f7";
  regs_addresses(202)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f8";
  regs_addresses(203)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"f9";
  regs_addresses(204)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"fa";
  regs_addresses(205)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"fb";
  regs_addresses(206)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"fc";
  regs_addresses(207)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"fd";
  regs_addresses(208)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"fe";
  regs_addresses(209)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "00" & x"ff";
  regs_addresses(210)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"00";
  regs_addresses(211)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"01";
  regs_addresses(212)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"02";
  regs_addresses(213)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"03";
  regs_addresses(214)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"04";
  regs_addresses(215)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"05";
  regs_addresses(216)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"06";
  regs_addresses(217)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"07";
  regs_addresses(218)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"08";
  regs_addresses(219)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"09";
  regs_addresses(220)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"0a";
  regs_addresses(221)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"10";
  regs_addresses(222)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"11";
  regs_addresses(223)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"12";
  regs_addresses(224)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"13";
  regs_addresses(225)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"14";
  regs_addresses(226)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"20";
  regs_addresses(227)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"21";
  regs_addresses(228)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"22";
  regs_addresses(229)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "01" & x"23";
  regs_addresses(230)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"00";
  regs_addresses(231)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"01";
  regs_addresses(232)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"02";
  regs_addresses(233)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"03";
  regs_addresses(234)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"04";
  regs_addresses(235)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"05";
  regs_addresses(236)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"06";
  regs_addresses(237)(REG_MT_ADDRESS_MSB downto REG_MT_ADDRESS_LSB) <= "10" & x"07";

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
  regs_read_arr(71)(REG_MT_FINE_DELAYS_LT0_MSB downto REG_MT_FINE_DELAYS_LT0_LSB) <= fine_delays(0);
  regs_read_arr(72)(REG_MT_FINE_DELAYS_LT1_MSB downto REG_MT_FINE_DELAYS_LT1_LSB) <= fine_delays(1);
  regs_read_arr(73)(REG_MT_FINE_DELAYS_LT2_MSB downto REG_MT_FINE_DELAYS_LT2_LSB) <= fine_delays(2);
  regs_read_arr(74)(REG_MT_FINE_DELAYS_LT3_MSB downto REG_MT_FINE_DELAYS_LT3_LSB) <= fine_delays(3);
  regs_read_arr(75)(REG_MT_FINE_DELAYS_LT4_MSB downto REG_MT_FINE_DELAYS_LT4_LSB) <= fine_delays(4);
  regs_read_arr(76)(REG_MT_FINE_DELAYS_LT5_MSB downto REG_MT_FINE_DELAYS_LT5_LSB) <= fine_delays(5);
  regs_read_arr(77)(REG_MT_FINE_DELAYS_LT6_MSB downto REG_MT_FINE_DELAYS_LT6_LSB) <= fine_delays(6);
  regs_read_arr(78)(REG_MT_FINE_DELAYS_LT7_MSB downto REG_MT_FINE_DELAYS_LT7_LSB) <= fine_delays(7);
  regs_read_arr(79)(REG_MT_FINE_DELAYS_LT8_MSB downto REG_MT_FINE_DELAYS_LT8_LSB) <= fine_delays(8);
  regs_read_arr(80)(REG_MT_FINE_DELAYS_LT9_MSB downto REG_MT_FINE_DELAYS_LT9_LSB) <= fine_delays(9);
  regs_read_arr(81)(REG_MT_FINE_DELAYS_LT10_MSB downto REG_MT_FINE_DELAYS_LT10_LSB) <= fine_delays(10);
  regs_read_arr(82)(REG_MT_FINE_DELAYS_LT11_MSB downto REG_MT_FINE_DELAYS_LT11_LSB) <= fine_delays(11);
  regs_read_arr(83)(REG_MT_FINE_DELAYS_LT12_MSB downto REG_MT_FINE_DELAYS_LT12_LSB) <= fine_delays(12);
  regs_read_arr(84)(REG_MT_FINE_DELAYS_LT13_MSB downto REG_MT_FINE_DELAYS_LT13_LSB) <= fine_delays(13);
  regs_read_arr(85)(REG_MT_FINE_DELAYS_LT14_MSB downto REG_MT_FINE_DELAYS_LT14_LSB) <= fine_delays(14);
  regs_read_arr(86)(REG_MT_FINE_DELAYS_LT15_MSB downto REG_MT_FINE_DELAYS_LT15_LSB) <= fine_delays(15);
  regs_read_arr(87)(REG_MT_FINE_DELAYS_LT16_MSB downto REG_MT_FINE_DELAYS_LT16_LSB) <= fine_delays(16);
  regs_read_arr(88)(REG_MT_FINE_DELAYS_LT17_MSB downto REG_MT_FINE_DELAYS_LT17_LSB) <= fine_delays(17);
  regs_read_arr(89)(REG_MT_FINE_DELAYS_LT18_MSB downto REG_MT_FINE_DELAYS_LT18_LSB) <= fine_delays(18);
  regs_read_arr(90)(REG_MT_FINE_DELAYS_LT19_MSB downto REG_MT_FINE_DELAYS_LT19_LSB) <= fine_delays(19);
  regs_read_arr(91)(REG_MT_FINE_DELAYS_LT20_MSB downto REG_MT_FINE_DELAYS_LT20_LSB) <= fine_delays(20);
  regs_read_arr(92)(REG_MT_FINE_DELAYS_LT21_MSB downto REG_MT_FINE_DELAYS_LT21_LSB) <= fine_delays(21);
  regs_read_arr(93)(REG_MT_FINE_DELAYS_LT22_MSB downto REG_MT_FINE_DELAYS_LT22_LSB) <= fine_delays(22);
  regs_read_arr(94)(REG_MT_FINE_DELAYS_LT23_MSB downto REG_MT_FINE_DELAYS_LT23_LSB) <= fine_delays(23);
  regs_read_arr(95)(REG_MT_FINE_DELAYS_LT24_MSB downto REG_MT_FINE_DELAYS_LT24_LSB) <= fine_delays(24);
  regs_read_arr(96)(REG_MT_FINE_DELAYS_LT25_MSB downto REG_MT_FINE_DELAYS_LT25_LSB) <= fine_delays(25);
  regs_read_arr(97)(REG_MT_FINE_DELAYS_LT26_MSB downto REG_MT_FINE_DELAYS_LT26_LSB) <= fine_delays(26);
  regs_read_arr(98)(REG_MT_FINE_DELAYS_LT27_MSB downto REG_MT_FINE_DELAYS_LT27_LSB) <= fine_delays(27);
  regs_read_arr(99)(REG_MT_FINE_DELAYS_LT28_MSB downto REG_MT_FINE_DELAYS_LT28_LSB) <= fine_delays(28);
  regs_read_arr(100)(REG_MT_FINE_DELAYS_LT29_MSB downto REG_MT_FINE_DELAYS_LT29_LSB) <= fine_delays(29);
  regs_read_arr(101)(REG_MT_FINE_DELAYS_LT30_MSB downto REG_MT_FINE_DELAYS_LT30_LSB) <= fine_delays(30);
  regs_read_arr(102)(REG_MT_FINE_DELAYS_LT31_MSB downto REG_MT_FINE_DELAYS_LT31_LSB) <= fine_delays(31);
  regs_read_arr(103)(REG_MT_FINE_DELAYS_LT32_MSB downto REG_MT_FINE_DELAYS_LT32_LSB) <= fine_delays(32);
  regs_read_arr(104)(REG_MT_FINE_DELAYS_LT33_MSB downto REG_MT_FINE_DELAYS_LT33_LSB) <= fine_delays(33);
  regs_read_arr(105)(REG_MT_FINE_DELAYS_LT34_MSB downto REG_MT_FINE_DELAYS_LT34_LSB) <= fine_delays(34);
  regs_read_arr(106)(REG_MT_FINE_DELAYS_LT35_MSB downto REG_MT_FINE_DELAYS_LT35_LSB) <= fine_delays(35);
  regs_read_arr(107)(REG_MT_FINE_DELAYS_LT36_MSB downto REG_MT_FINE_DELAYS_LT36_LSB) <= fine_delays(36);
  regs_read_arr(108)(REG_MT_FINE_DELAYS_LT37_MSB downto REG_MT_FINE_DELAYS_LT37_LSB) <= fine_delays(37);
  regs_read_arr(109)(REG_MT_FINE_DELAYS_LT38_MSB downto REG_MT_FINE_DELAYS_LT38_LSB) <= fine_delays(38);
  regs_read_arr(110)(REG_MT_FINE_DELAYS_LT39_MSB downto REG_MT_FINE_DELAYS_LT39_LSB) <= fine_delays(39);
  regs_read_arr(111)(REG_MT_FINE_DELAYS_LT40_MSB downto REG_MT_FINE_DELAYS_LT40_LSB) <= fine_delays(40);
  regs_read_arr(112)(REG_MT_FINE_DELAYS_LT41_MSB downto REG_MT_FINE_DELAYS_LT41_LSB) <= fine_delays(41);
  regs_read_arr(113)(REG_MT_FINE_DELAYS_LT42_MSB downto REG_MT_FINE_DELAYS_LT42_LSB) <= fine_delays(42);
  regs_read_arr(114)(REG_MT_FINE_DELAYS_LT43_MSB downto REG_MT_FINE_DELAYS_LT43_LSB) <= fine_delays(43);
  regs_read_arr(115)(REG_MT_FINE_DELAYS_LT44_MSB downto REG_MT_FINE_DELAYS_LT44_LSB) <= fine_delays(44);
  regs_read_arr(116)(REG_MT_FINE_DELAYS_LT45_MSB downto REG_MT_FINE_DELAYS_LT45_LSB) <= fine_delays(45);
  regs_read_arr(117)(REG_MT_FINE_DELAYS_LT46_MSB downto REG_MT_FINE_DELAYS_LT46_LSB) <= fine_delays(46);
  regs_read_arr(118)(REG_MT_FINE_DELAYS_LT47_MSB downto REG_MT_FINE_DELAYS_LT47_LSB) <= fine_delays(47);
  regs_read_arr(119)(REG_MT_FINE_DELAYS_LT48_MSB downto REG_MT_FINE_DELAYS_LT48_LSB) <= fine_delays(48);
  regs_read_arr(120)(REG_MT_FINE_DELAYS_LT49_MSB downto REG_MT_FINE_DELAYS_LT49_LSB) <= fine_delays(49);
  regs_read_arr(121)(REG_MT_FINE_DELAYS_LT50_MSB downto REG_MT_FINE_DELAYS_LT50_LSB) <= fine_delays(50);
  regs_read_arr(122)(REG_MT_FINE_DELAYS_LT51_MSB downto REG_MT_FINE_DELAYS_LT51_LSB) <= fine_delays(51);
  regs_read_arr(123)(REG_MT_FINE_DELAYS_LT52_MSB downto REG_MT_FINE_DELAYS_LT52_LSB) <= fine_delays(52);
  regs_read_arr(124)(REG_MT_FINE_DELAYS_LT53_MSB downto REG_MT_FINE_DELAYS_LT53_LSB) <= fine_delays(53);
  regs_read_arr(125)(REG_MT_FINE_DELAYS_LT54_MSB downto REG_MT_FINE_DELAYS_LT54_LSB) <= fine_delays(54);
  regs_read_arr(126)(REG_MT_FINE_DELAYS_LT55_MSB downto REG_MT_FINE_DELAYS_LT55_LSB) <= fine_delays(55);
  regs_read_arr(127)(REG_MT_FINE_DELAYS_LT56_MSB downto REG_MT_FINE_DELAYS_LT56_LSB) <= fine_delays(56);
  regs_read_arr(128)(REG_MT_FINE_DELAYS_LT57_MSB downto REG_MT_FINE_DELAYS_LT57_LSB) <= fine_delays(57);
  regs_read_arr(129)(REG_MT_FINE_DELAYS_LT58_MSB downto REG_MT_FINE_DELAYS_LT58_LSB) <= fine_delays(58);
  regs_read_arr(130)(REG_MT_FINE_DELAYS_LT59_MSB downto REG_MT_FINE_DELAYS_LT59_LSB) <= fine_delays(59);
  regs_read_arr(131)(REG_MT_FINE_DELAYS_LT60_MSB downto REG_MT_FINE_DELAYS_LT60_LSB) <= fine_delays(60);
  regs_read_arr(132)(REG_MT_FINE_DELAYS_LT61_MSB downto REG_MT_FINE_DELAYS_LT61_LSB) <= fine_delays(61);
  regs_read_arr(133)(REG_MT_FINE_DELAYS_LT62_MSB downto REG_MT_FINE_DELAYS_LT62_LSB) <= fine_delays(62);
  regs_read_arr(134)(REG_MT_FINE_DELAYS_LT63_MSB downto REG_MT_FINE_DELAYS_LT63_LSB) <= fine_delays(63);
  regs_read_arr(135)(REG_MT_FINE_DELAYS_LT64_MSB downto REG_MT_FINE_DELAYS_LT64_LSB) <= fine_delays(64);
  regs_read_arr(136)(REG_MT_FINE_DELAYS_LT65_MSB downto REG_MT_FINE_DELAYS_LT65_LSB) <= fine_delays(65);
  regs_read_arr(137)(REG_MT_FINE_DELAYS_LT66_MSB downto REG_MT_FINE_DELAYS_LT66_LSB) <= fine_delays(66);
  regs_read_arr(138)(REG_MT_FINE_DELAYS_LT67_MSB downto REG_MT_FINE_DELAYS_LT67_LSB) <= fine_delays(67);
  regs_read_arr(139)(REG_MT_FINE_DELAYS_LT68_MSB downto REG_MT_FINE_DELAYS_LT68_LSB) <= fine_delays(68);
  regs_read_arr(140)(REG_MT_FINE_DELAYS_LT69_MSB downto REG_MT_FINE_DELAYS_LT69_LSB) <= fine_delays(69);
  regs_read_arr(141)(REG_MT_FINE_DELAYS_LT70_MSB downto REG_MT_FINE_DELAYS_LT70_LSB) <= fine_delays(70);
  regs_read_arr(142)(REG_MT_FINE_DELAYS_LT71_MSB downto REG_MT_FINE_DELAYS_LT71_LSB) <= fine_delays(71);
  regs_read_arr(143)(REG_MT_FINE_DELAYS_LT72_MSB downto REG_MT_FINE_DELAYS_LT72_LSB) <= fine_delays(72);
  regs_read_arr(144)(REG_MT_FINE_DELAYS_LT73_MSB downto REG_MT_FINE_DELAYS_LT73_LSB) <= fine_delays(73);
  regs_read_arr(145)(REG_MT_FINE_DELAYS_LT74_MSB downto REG_MT_FINE_DELAYS_LT74_LSB) <= fine_delays(74);
  regs_read_arr(146)(REG_MT_COARSE_DELAYS_LT0_MSB downto REG_MT_COARSE_DELAYS_LT0_LSB) <= coarse_delays(0);
  regs_read_arr(147)(REG_MT_COARSE_DELAYS_LT1_MSB downto REG_MT_COARSE_DELAYS_LT1_LSB) <= coarse_delays(1);
  regs_read_arr(148)(REG_MT_COARSE_DELAYS_LT2_MSB downto REG_MT_COARSE_DELAYS_LT2_LSB) <= coarse_delays(2);
  regs_read_arr(149)(REG_MT_COARSE_DELAYS_LT3_MSB downto REG_MT_COARSE_DELAYS_LT3_LSB) <= coarse_delays(3);
  regs_read_arr(150)(REG_MT_COARSE_DELAYS_LT4_MSB downto REG_MT_COARSE_DELAYS_LT4_LSB) <= coarse_delays(4);
  regs_read_arr(151)(REG_MT_COARSE_DELAYS_LT5_MSB downto REG_MT_COARSE_DELAYS_LT5_LSB) <= coarse_delays(5);
  regs_read_arr(152)(REG_MT_COARSE_DELAYS_LT6_MSB downto REG_MT_COARSE_DELAYS_LT6_LSB) <= coarse_delays(6);
  regs_read_arr(153)(REG_MT_COARSE_DELAYS_LT7_MSB downto REG_MT_COARSE_DELAYS_LT7_LSB) <= coarse_delays(7);
  regs_read_arr(154)(REG_MT_COARSE_DELAYS_LT8_MSB downto REG_MT_COARSE_DELAYS_LT8_LSB) <= coarse_delays(8);
  regs_read_arr(155)(REG_MT_COARSE_DELAYS_LT9_MSB downto REG_MT_COARSE_DELAYS_LT9_LSB) <= coarse_delays(9);
  regs_read_arr(156)(REG_MT_COARSE_DELAYS_LT10_MSB downto REG_MT_COARSE_DELAYS_LT10_LSB) <= coarse_delays(10);
  regs_read_arr(157)(REG_MT_COARSE_DELAYS_LT11_MSB downto REG_MT_COARSE_DELAYS_LT11_LSB) <= coarse_delays(11);
  regs_read_arr(158)(REG_MT_COARSE_DELAYS_LT12_MSB downto REG_MT_COARSE_DELAYS_LT12_LSB) <= coarse_delays(12);
  regs_read_arr(159)(REG_MT_COARSE_DELAYS_LT13_MSB downto REG_MT_COARSE_DELAYS_LT13_LSB) <= coarse_delays(13);
  regs_read_arr(160)(REG_MT_COARSE_DELAYS_LT14_MSB downto REG_MT_COARSE_DELAYS_LT14_LSB) <= coarse_delays(14);
  regs_read_arr(161)(REG_MT_COARSE_DELAYS_LT15_MSB downto REG_MT_COARSE_DELAYS_LT15_LSB) <= coarse_delays(15);
  regs_read_arr(162)(REG_MT_COARSE_DELAYS_LT16_MSB downto REG_MT_COARSE_DELAYS_LT16_LSB) <= coarse_delays(16);
  regs_read_arr(163)(REG_MT_COARSE_DELAYS_LT17_MSB downto REG_MT_COARSE_DELAYS_LT17_LSB) <= coarse_delays(17);
  regs_read_arr(164)(REG_MT_COARSE_DELAYS_LT18_MSB downto REG_MT_COARSE_DELAYS_LT18_LSB) <= coarse_delays(18);
  regs_read_arr(165)(REG_MT_COARSE_DELAYS_LT19_MSB downto REG_MT_COARSE_DELAYS_LT19_LSB) <= coarse_delays(19);
  regs_read_arr(166)(REG_MT_COARSE_DELAYS_LT20_MSB downto REG_MT_COARSE_DELAYS_LT20_LSB) <= coarse_delays(20);
  regs_read_arr(167)(REG_MT_COARSE_DELAYS_LT21_MSB downto REG_MT_COARSE_DELAYS_LT21_LSB) <= coarse_delays(21);
  regs_read_arr(168)(REG_MT_COARSE_DELAYS_LT22_MSB downto REG_MT_COARSE_DELAYS_LT22_LSB) <= coarse_delays(22);
  regs_read_arr(169)(REG_MT_COARSE_DELAYS_LT23_MSB downto REG_MT_COARSE_DELAYS_LT23_LSB) <= coarse_delays(23);
  regs_read_arr(170)(REG_MT_COARSE_DELAYS_LT24_MSB downto REG_MT_COARSE_DELAYS_LT24_LSB) <= coarse_delays(24);
  regs_read_arr(171)(REG_MT_COARSE_DELAYS_LT25_MSB downto REG_MT_COARSE_DELAYS_LT25_LSB) <= coarse_delays(25);
  regs_read_arr(172)(REG_MT_COARSE_DELAYS_LT26_MSB downto REG_MT_COARSE_DELAYS_LT26_LSB) <= coarse_delays(26);
  regs_read_arr(173)(REG_MT_COARSE_DELAYS_LT27_MSB downto REG_MT_COARSE_DELAYS_LT27_LSB) <= coarse_delays(27);
  regs_read_arr(174)(REG_MT_COARSE_DELAYS_LT28_MSB downto REG_MT_COARSE_DELAYS_LT28_LSB) <= coarse_delays(28);
  regs_read_arr(175)(REG_MT_COARSE_DELAYS_LT29_MSB downto REG_MT_COARSE_DELAYS_LT29_LSB) <= coarse_delays(29);
  regs_read_arr(176)(REG_MT_COARSE_DELAYS_LT30_MSB downto REG_MT_COARSE_DELAYS_LT30_LSB) <= coarse_delays(30);
  regs_read_arr(177)(REG_MT_COARSE_DELAYS_LT31_MSB downto REG_MT_COARSE_DELAYS_LT31_LSB) <= coarse_delays(31);
  regs_read_arr(178)(REG_MT_COARSE_DELAYS_LT32_MSB downto REG_MT_COARSE_DELAYS_LT32_LSB) <= coarse_delays(32);
  regs_read_arr(179)(REG_MT_COARSE_DELAYS_LT33_MSB downto REG_MT_COARSE_DELAYS_LT33_LSB) <= coarse_delays(33);
  regs_read_arr(180)(REG_MT_COARSE_DELAYS_LT34_MSB downto REG_MT_COARSE_DELAYS_LT34_LSB) <= coarse_delays(34);
  regs_read_arr(181)(REG_MT_COARSE_DELAYS_LT35_MSB downto REG_MT_COARSE_DELAYS_LT35_LSB) <= coarse_delays(35);
  regs_read_arr(182)(REG_MT_COARSE_DELAYS_LT36_MSB downto REG_MT_COARSE_DELAYS_LT36_LSB) <= coarse_delays(36);
  regs_read_arr(183)(REG_MT_COARSE_DELAYS_LT37_MSB downto REG_MT_COARSE_DELAYS_LT37_LSB) <= coarse_delays(37);
  regs_read_arr(184)(REG_MT_COARSE_DELAYS_LT38_MSB downto REG_MT_COARSE_DELAYS_LT38_LSB) <= coarse_delays(38);
  regs_read_arr(185)(REG_MT_COARSE_DELAYS_LT39_MSB downto REG_MT_COARSE_DELAYS_LT39_LSB) <= coarse_delays(39);
  regs_read_arr(186)(REG_MT_COARSE_DELAYS_LT40_MSB downto REG_MT_COARSE_DELAYS_LT40_LSB) <= coarse_delays(40);
  regs_read_arr(187)(REG_MT_COARSE_DELAYS_LT41_MSB downto REG_MT_COARSE_DELAYS_LT41_LSB) <= coarse_delays(41);
  regs_read_arr(188)(REG_MT_COARSE_DELAYS_LT42_MSB downto REG_MT_COARSE_DELAYS_LT42_LSB) <= coarse_delays(42);
  regs_read_arr(189)(REG_MT_COARSE_DELAYS_LT43_MSB downto REG_MT_COARSE_DELAYS_LT43_LSB) <= coarse_delays(43);
  regs_read_arr(190)(REG_MT_COARSE_DELAYS_LT44_MSB downto REG_MT_COARSE_DELAYS_LT44_LSB) <= coarse_delays(44);
  regs_read_arr(191)(REG_MT_COARSE_DELAYS_LT45_MSB downto REG_MT_COARSE_DELAYS_LT45_LSB) <= coarse_delays(45);
  regs_read_arr(192)(REG_MT_COARSE_DELAYS_LT46_MSB downto REG_MT_COARSE_DELAYS_LT46_LSB) <= coarse_delays(46);
  regs_read_arr(193)(REG_MT_COARSE_DELAYS_LT47_MSB downto REG_MT_COARSE_DELAYS_LT47_LSB) <= coarse_delays(47);
  regs_read_arr(194)(REG_MT_COARSE_DELAYS_LT48_MSB downto REG_MT_COARSE_DELAYS_LT48_LSB) <= coarse_delays(48);
  regs_read_arr(195)(REG_MT_COARSE_DELAYS_LT49_MSB downto REG_MT_COARSE_DELAYS_LT49_LSB) <= coarse_delays(49);
  regs_read_arr(196)(REG_MT_COARSE_DELAYS_LT50_MSB downto REG_MT_COARSE_DELAYS_LT50_LSB) <= coarse_delays(50);
  regs_read_arr(197)(REG_MT_COARSE_DELAYS_LT51_MSB downto REG_MT_COARSE_DELAYS_LT51_LSB) <= coarse_delays(51);
  regs_read_arr(198)(REG_MT_COARSE_DELAYS_LT52_MSB downto REG_MT_COARSE_DELAYS_LT52_LSB) <= coarse_delays(52);
  regs_read_arr(199)(REG_MT_COARSE_DELAYS_LT53_MSB downto REG_MT_COARSE_DELAYS_LT53_LSB) <= coarse_delays(53);
  regs_read_arr(200)(REG_MT_COARSE_DELAYS_LT54_MSB downto REG_MT_COARSE_DELAYS_LT54_LSB) <= coarse_delays(54);
  regs_read_arr(201)(REG_MT_COARSE_DELAYS_LT55_MSB downto REG_MT_COARSE_DELAYS_LT55_LSB) <= coarse_delays(55);
  regs_read_arr(202)(REG_MT_COARSE_DELAYS_LT56_MSB downto REG_MT_COARSE_DELAYS_LT56_LSB) <= coarse_delays(56);
  regs_read_arr(203)(REG_MT_COARSE_DELAYS_LT57_MSB downto REG_MT_COARSE_DELAYS_LT57_LSB) <= coarse_delays(57);
  regs_read_arr(204)(REG_MT_COARSE_DELAYS_LT58_MSB downto REG_MT_COARSE_DELAYS_LT58_LSB) <= coarse_delays(58);
  regs_read_arr(205)(REG_MT_COARSE_DELAYS_LT59_MSB downto REG_MT_COARSE_DELAYS_LT59_LSB) <= coarse_delays(59);
  regs_read_arr(206)(REG_MT_COARSE_DELAYS_LT60_MSB downto REG_MT_COARSE_DELAYS_LT60_LSB) <= coarse_delays(60);
  regs_read_arr(207)(REG_MT_COARSE_DELAYS_LT61_MSB downto REG_MT_COARSE_DELAYS_LT61_LSB) <= coarse_delays(61);
  regs_read_arr(208)(REG_MT_COARSE_DELAYS_LT62_MSB downto REG_MT_COARSE_DELAYS_LT62_LSB) <= coarse_delays(62);
  regs_read_arr(209)(REG_MT_COARSE_DELAYS_LT63_MSB downto REG_MT_COARSE_DELAYS_LT63_LSB) <= coarse_delays(63);
  regs_read_arr(210)(REG_MT_COARSE_DELAYS_LT64_MSB downto REG_MT_COARSE_DELAYS_LT64_LSB) <= coarse_delays(64);
  regs_read_arr(211)(REG_MT_COARSE_DELAYS_LT65_MSB downto REG_MT_COARSE_DELAYS_LT65_LSB) <= coarse_delays(65);
  regs_read_arr(212)(REG_MT_COARSE_DELAYS_LT66_MSB downto REG_MT_COARSE_DELAYS_LT66_LSB) <= coarse_delays(66);
  regs_read_arr(213)(REG_MT_COARSE_DELAYS_LT67_MSB downto REG_MT_COARSE_DELAYS_LT67_LSB) <= coarse_delays(67);
  regs_read_arr(214)(REG_MT_COARSE_DELAYS_LT68_MSB downto REG_MT_COARSE_DELAYS_LT68_LSB) <= coarse_delays(68);
  regs_read_arr(215)(REG_MT_COARSE_DELAYS_LT69_MSB downto REG_MT_COARSE_DELAYS_LT69_LSB) <= coarse_delays(69);
  regs_read_arr(216)(REG_MT_COARSE_DELAYS_LT70_MSB downto REG_MT_COARSE_DELAYS_LT70_LSB) <= coarse_delays(70);
  regs_read_arr(217)(REG_MT_COARSE_DELAYS_LT71_MSB downto REG_MT_COARSE_DELAYS_LT71_LSB) <= coarse_delays(71);
  regs_read_arr(218)(REG_MT_COARSE_DELAYS_LT72_MSB downto REG_MT_COARSE_DELAYS_LT72_LSB) <= coarse_delays(72);
  regs_read_arr(219)(REG_MT_COARSE_DELAYS_LT73_MSB downto REG_MT_COARSE_DELAYS_LT73_LSB) <= coarse_delays(73);
  regs_read_arr(220)(REG_MT_COARSE_DELAYS_LT74_MSB downto REG_MT_COARSE_DELAYS_LT74_LSB) <= coarse_delays(74);
  regs_read_arr(221)(REG_MT_POSNEGS_DSI0_MSB downto REG_MT_POSNEGS_DSI0_LSB) <= posnegs_dsi0;
  regs_read_arr(222)(REG_MT_POSNEGS_DSI1_MSB downto REG_MT_POSNEGS_DSI1_LSB) <= posnegs_dsi1;
  regs_read_arr(223)(REG_MT_POSNEGS_DSI2_MSB downto REG_MT_POSNEGS_DSI2_LSB) <= posnegs_dsi2;
  regs_read_arr(224)(REG_MT_POSNEGS_DSI3_MSB downto REG_MT_POSNEGS_DSI3_LSB) <= posnegs_dsi3;
  regs_read_arr(225)(REG_MT_POSNEGS_DSI4_MSB downto REG_MT_POSNEGS_DSI4_LSB) <= posnegs_dsi4;
  regs_read_arr(226)(REG_MT_XADC_CALIBRATION_MSB downto REG_MT_XADC_CALIBRATION_LSB) <= calibration;
  regs_read_arr(226)(REG_MT_XADC_VCCPINT_MSB downto REG_MT_XADC_VCCPINT_LSB) <= vccpint;
  regs_read_arr(227)(REG_MT_XADC_VCCPAUX_MSB downto REG_MT_XADC_VCCPAUX_LSB) <= vccpaux;
  regs_read_arr(227)(REG_MT_XADC_VCCODDR_MSB downto REG_MT_XADC_VCCODDR_LSB) <= vccoddr;
  regs_read_arr(228)(REG_MT_XADC_TEMP_MSB downto REG_MT_XADC_TEMP_LSB) <= temp;
  regs_read_arr(228)(REG_MT_XADC_VCCINT_MSB downto REG_MT_XADC_VCCINT_LSB) <= vccint;
  regs_read_arr(229)(REG_MT_XADC_VCCAUX_MSB downto REG_MT_XADC_VCCAUX_LSB) <= vccaux;
  regs_read_arr(229)(REG_MT_XADC_VCCBRAM_MSB downto REG_MT_XADC_VCCBRAM_LSB) <= vccbram;
  regs_read_arr(230)(REG_MT_HOG_GLOBAL_DATE_MSB downto REG_MT_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
  regs_read_arr(231)(REG_MT_HOG_GLOBAL_TIME_MSB downto REG_MT_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
  regs_read_arr(232)(REG_MT_HOG_GLOBAL_VER_MSB downto REG_MT_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
  regs_read_arr(233)(REG_MT_HOG_GLOBAL_SHA_MSB downto REG_MT_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
  regs_read_arr(234)(REG_MT_HOG_TOP_SHA_MSB downto REG_MT_HOG_TOP_SHA_LSB) <= TOP_SHA;
  regs_read_arr(235)(REG_MT_HOG_TOP_VER_MSB downto REG_MT_HOG_TOP_VER_LSB) <= TOP_VER;
  regs_read_arr(236)(REG_MT_HOG_HOG_SHA_MSB downto REG_MT_HOG_HOG_SHA_LSB) <= HOG_SHA;
  regs_read_arr(237)(REG_MT_HOG_HOG_VER_MSB downto REG_MT_HOG_HOG_VER_LSB) <= HOG_VER;

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
  fine_delays(0) <= regs_write_arr(71)(REG_MT_FINE_DELAYS_LT0_MSB downto REG_MT_FINE_DELAYS_LT0_LSB);
  fine_delays(1) <= regs_write_arr(72)(REG_MT_FINE_DELAYS_LT1_MSB downto REG_MT_FINE_DELAYS_LT1_LSB);
  fine_delays(2) <= regs_write_arr(73)(REG_MT_FINE_DELAYS_LT2_MSB downto REG_MT_FINE_DELAYS_LT2_LSB);
  fine_delays(3) <= regs_write_arr(74)(REG_MT_FINE_DELAYS_LT3_MSB downto REG_MT_FINE_DELAYS_LT3_LSB);
  fine_delays(4) <= regs_write_arr(75)(REG_MT_FINE_DELAYS_LT4_MSB downto REG_MT_FINE_DELAYS_LT4_LSB);
  fine_delays(5) <= regs_write_arr(76)(REG_MT_FINE_DELAYS_LT5_MSB downto REG_MT_FINE_DELAYS_LT5_LSB);
  fine_delays(6) <= regs_write_arr(77)(REG_MT_FINE_DELAYS_LT6_MSB downto REG_MT_FINE_DELAYS_LT6_LSB);
  fine_delays(7) <= regs_write_arr(78)(REG_MT_FINE_DELAYS_LT7_MSB downto REG_MT_FINE_DELAYS_LT7_LSB);
  fine_delays(8) <= regs_write_arr(79)(REG_MT_FINE_DELAYS_LT8_MSB downto REG_MT_FINE_DELAYS_LT8_LSB);
  fine_delays(9) <= regs_write_arr(80)(REG_MT_FINE_DELAYS_LT9_MSB downto REG_MT_FINE_DELAYS_LT9_LSB);
  fine_delays(10) <= regs_write_arr(81)(REG_MT_FINE_DELAYS_LT10_MSB downto REG_MT_FINE_DELAYS_LT10_LSB);
  fine_delays(11) <= regs_write_arr(82)(REG_MT_FINE_DELAYS_LT11_MSB downto REG_MT_FINE_DELAYS_LT11_LSB);
  fine_delays(12) <= regs_write_arr(83)(REG_MT_FINE_DELAYS_LT12_MSB downto REG_MT_FINE_DELAYS_LT12_LSB);
  fine_delays(13) <= regs_write_arr(84)(REG_MT_FINE_DELAYS_LT13_MSB downto REG_MT_FINE_DELAYS_LT13_LSB);
  fine_delays(14) <= regs_write_arr(85)(REG_MT_FINE_DELAYS_LT14_MSB downto REG_MT_FINE_DELAYS_LT14_LSB);
  fine_delays(15) <= regs_write_arr(86)(REG_MT_FINE_DELAYS_LT15_MSB downto REG_MT_FINE_DELAYS_LT15_LSB);
  fine_delays(16) <= regs_write_arr(87)(REG_MT_FINE_DELAYS_LT16_MSB downto REG_MT_FINE_DELAYS_LT16_LSB);
  fine_delays(17) <= regs_write_arr(88)(REG_MT_FINE_DELAYS_LT17_MSB downto REG_MT_FINE_DELAYS_LT17_LSB);
  fine_delays(18) <= regs_write_arr(89)(REG_MT_FINE_DELAYS_LT18_MSB downto REG_MT_FINE_DELAYS_LT18_LSB);
  fine_delays(19) <= regs_write_arr(90)(REG_MT_FINE_DELAYS_LT19_MSB downto REG_MT_FINE_DELAYS_LT19_LSB);
  fine_delays(20) <= regs_write_arr(91)(REG_MT_FINE_DELAYS_LT20_MSB downto REG_MT_FINE_DELAYS_LT20_LSB);
  fine_delays(21) <= regs_write_arr(92)(REG_MT_FINE_DELAYS_LT21_MSB downto REG_MT_FINE_DELAYS_LT21_LSB);
  fine_delays(22) <= regs_write_arr(93)(REG_MT_FINE_DELAYS_LT22_MSB downto REG_MT_FINE_DELAYS_LT22_LSB);
  fine_delays(23) <= regs_write_arr(94)(REG_MT_FINE_DELAYS_LT23_MSB downto REG_MT_FINE_DELAYS_LT23_LSB);
  fine_delays(24) <= regs_write_arr(95)(REG_MT_FINE_DELAYS_LT24_MSB downto REG_MT_FINE_DELAYS_LT24_LSB);
  fine_delays(25) <= regs_write_arr(96)(REG_MT_FINE_DELAYS_LT25_MSB downto REG_MT_FINE_DELAYS_LT25_LSB);
  fine_delays(26) <= regs_write_arr(97)(REG_MT_FINE_DELAYS_LT26_MSB downto REG_MT_FINE_DELAYS_LT26_LSB);
  fine_delays(27) <= regs_write_arr(98)(REG_MT_FINE_DELAYS_LT27_MSB downto REG_MT_FINE_DELAYS_LT27_LSB);
  fine_delays(28) <= regs_write_arr(99)(REG_MT_FINE_DELAYS_LT28_MSB downto REG_MT_FINE_DELAYS_LT28_LSB);
  fine_delays(29) <= regs_write_arr(100)(REG_MT_FINE_DELAYS_LT29_MSB downto REG_MT_FINE_DELAYS_LT29_LSB);
  fine_delays(30) <= regs_write_arr(101)(REG_MT_FINE_DELAYS_LT30_MSB downto REG_MT_FINE_DELAYS_LT30_LSB);
  fine_delays(31) <= regs_write_arr(102)(REG_MT_FINE_DELAYS_LT31_MSB downto REG_MT_FINE_DELAYS_LT31_LSB);
  fine_delays(32) <= regs_write_arr(103)(REG_MT_FINE_DELAYS_LT32_MSB downto REG_MT_FINE_DELAYS_LT32_LSB);
  fine_delays(33) <= regs_write_arr(104)(REG_MT_FINE_DELAYS_LT33_MSB downto REG_MT_FINE_DELAYS_LT33_LSB);
  fine_delays(34) <= regs_write_arr(105)(REG_MT_FINE_DELAYS_LT34_MSB downto REG_MT_FINE_DELAYS_LT34_LSB);
  fine_delays(35) <= regs_write_arr(106)(REG_MT_FINE_DELAYS_LT35_MSB downto REG_MT_FINE_DELAYS_LT35_LSB);
  fine_delays(36) <= regs_write_arr(107)(REG_MT_FINE_DELAYS_LT36_MSB downto REG_MT_FINE_DELAYS_LT36_LSB);
  fine_delays(37) <= regs_write_arr(108)(REG_MT_FINE_DELAYS_LT37_MSB downto REG_MT_FINE_DELAYS_LT37_LSB);
  fine_delays(38) <= regs_write_arr(109)(REG_MT_FINE_DELAYS_LT38_MSB downto REG_MT_FINE_DELAYS_LT38_LSB);
  fine_delays(39) <= regs_write_arr(110)(REG_MT_FINE_DELAYS_LT39_MSB downto REG_MT_FINE_DELAYS_LT39_LSB);
  fine_delays(40) <= regs_write_arr(111)(REG_MT_FINE_DELAYS_LT40_MSB downto REG_MT_FINE_DELAYS_LT40_LSB);
  fine_delays(41) <= regs_write_arr(112)(REG_MT_FINE_DELAYS_LT41_MSB downto REG_MT_FINE_DELAYS_LT41_LSB);
  fine_delays(42) <= regs_write_arr(113)(REG_MT_FINE_DELAYS_LT42_MSB downto REG_MT_FINE_DELAYS_LT42_LSB);
  fine_delays(43) <= regs_write_arr(114)(REG_MT_FINE_DELAYS_LT43_MSB downto REG_MT_FINE_DELAYS_LT43_LSB);
  fine_delays(44) <= regs_write_arr(115)(REG_MT_FINE_DELAYS_LT44_MSB downto REG_MT_FINE_DELAYS_LT44_LSB);
  fine_delays(45) <= regs_write_arr(116)(REG_MT_FINE_DELAYS_LT45_MSB downto REG_MT_FINE_DELAYS_LT45_LSB);
  fine_delays(46) <= regs_write_arr(117)(REG_MT_FINE_DELAYS_LT46_MSB downto REG_MT_FINE_DELAYS_LT46_LSB);
  fine_delays(47) <= regs_write_arr(118)(REG_MT_FINE_DELAYS_LT47_MSB downto REG_MT_FINE_DELAYS_LT47_LSB);
  fine_delays(48) <= regs_write_arr(119)(REG_MT_FINE_DELAYS_LT48_MSB downto REG_MT_FINE_DELAYS_LT48_LSB);
  fine_delays(49) <= regs_write_arr(120)(REG_MT_FINE_DELAYS_LT49_MSB downto REG_MT_FINE_DELAYS_LT49_LSB);
  fine_delays(50) <= regs_write_arr(121)(REG_MT_FINE_DELAYS_LT50_MSB downto REG_MT_FINE_DELAYS_LT50_LSB);
  fine_delays(51) <= regs_write_arr(122)(REG_MT_FINE_DELAYS_LT51_MSB downto REG_MT_FINE_DELAYS_LT51_LSB);
  fine_delays(52) <= regs_write_arr(123)(REG_MT_FINE_DELAYS_LT52_MSB downto REG_MT_FINE_DELAYS_LT52_LSB);
  fine_delays(53) <= regs_write_arr(124)(REG_MT_FINE_DELAYS_LT53_MSB downto REG_MT_FINE_DELAYS_LT53_LSB);
  fine_delays(54) <= regs_write_arr(125)(REG_MT_FINE_DELAYS_LT54_MSB downto REG_MT_FINE_DELAYS_LT54_LSB);
  fine_delays(55) <= regs_write_arr(126)(REG_MT_FINE_DELAYS_LT55_MSB downto REG_MT_FINE_DELAYS_LT55_LSB);
  fine_delays(56) <= regs_write_arr(127)(REG_MT_FINE_DELAYS_LT56_MSB downto REG_MT_FINE_DELAYS_LT56_LSB);
  fine_delays(57) <= regs_write_arr(128)(REG_MT_FINE_DELAYS_LT57_MSB downto REG_MT_FINE_DELAYS_LT57_LSB);
  fine_delays(58) <= regs_write_arr(129)(REG_MT_FINE_DELAYS_LT58_MSB downto REG_MT_FINE_DELAYS_LT58_LSB);
  fine_delays(59) <= regs_write_arr(130)(REG_MT_FINE_DELAYS_LT59_MSB downto REG_MT_FINE_DELAYS_LT59_LSB);
  fine_delays(60) <= regs_write_arr(131)(REG_MT_FINE_DELAYS_LT60_MSB downto REG_MT_FINE_DELAYS_LT60_LSB);
  fine_delays(61) <= regs_write_arr(132)(REG_MT_FINE_DELAYS_LT61_MSB downto REG_MT_FINE_DELAYS_LT61_LSB);
  fine_delays(62) <= regs_write_arr(133)(REG_MT_FINE_DELAYS_LT62_MSB downto REG_MT_FINE_DELAYS_LT62_LSB);
  fine_delays(63) <= regs_write_arr(134)(REG_MT_FINE_DELAYS_LT63_MSB downto REG_MT_FINE_DELAYS_LT63_LSB);
  fine_delays(64) <= regs_write_arr(135)(REG_MT_FINE_DELAYS_LT64_MSB downto REG_MT_FINE_DELAYS_LT64_LSB);
  fine_delays(65) <= regs_write_arr(136)(REG_MT_FINE_DELAYS_LT65_MSB downto REG_MT_FINE_DELAYS_LT65_LSB);
  fine_delays(66) <= regs_write_arr(137)(REG_MT_FINE_DELAYS_LT66_MSB downto REG_MT_FINE_DELAYS_LT66_LSB);
  fine_delays(67) <= regs_write_arr(138)(REG_MT_FINE_DELAYS_LT67_MSB downto REG_MT_FINE_DELAYS_LT67_LSB);
  fine_delays(68) <= regs_write_arr(139)(REG_MT_FINE_DELAYS_LT68_MSB downto REG_MT_FINE_DELAYS_LT68_LSB);
  fine_delays(69) <= regs_write_arr(140)(REG_MT_FINE_DELAYS_LT69_MSB downto REG_MT_FINE_DELAYS_LT69_LSB);
  fine_delays(70) <= regs_write_arr(141)(REG_MT_FINE_DELAYS_LT70_MSB downto REG_MT_FINE_DELAYS_LT70_LSB);
  fine_delays(71) <= regs_write_arr(142)(REG_MT_FINE_DELAYS_LT71_MSB downto REG_MT_FINE_DELAYS_LT71_LSB);
  fine_delays(72) <= regs_write_arr(143)(REG_MT_FINE_DELAYS_LT72_MSB downto REG_MT_FINE_DELAYS_LT72_LSB);
  fine_delays(73) <= regs_write_arr(144)(REG_MT_FINE_DELAYS_LT73_MSB downto REG_MT_FINE_DELAYS_LT73_LSB);
  fine_delays(74) <= regs_write_arr(145)(REG_MT_FINE_DELAYS_LT74_MSB downto REG_MT_FINE_DELAYS_LT74_LSB);
  coarse_delays(0) <= regs_write_arr(146)(REG_MT_COARSE_DELAYS_LT0_MSB downto REG_MT_COARSE_DELAYS_LT0_LSB);
  coarse_delays(1) <= regs_write_arr(147)(REG_MT_COARSE_DELAYS_LT1_MSB downto REG_MT_COARSE_DELAYS_LT1_LSB);
  coarse_delays(2) <= regs_write_arr(148)(REG_MT_COARSE_DELAYS_LT2_MSB downto REG_MT_COARSE_DELAYS_LT2_LSB);
  coarse_delays(3) <= regs_write_arr(149)(REG_MT_COARSE_DELAYS_LT3_MSB downto REG_MT_COARSE_DELAYS_LT3_LSB);
  coarse_delays(4) <= regs_write_arr(150)(REG_MT_COARSE_DELAYS_LT4_MSB downto REG_MT_COARSE_DELAYS_LT4_LSB);
  coarse_delays(5) <= regs_write_arr(151)(REG_MT_COARSE_DELAYS_LT5_MSB downto REG_MT_COARSE_DELAYS_LT5_LSB);
  coarse_delays(6) <= regs_write_arr(152)(REG_MT_COARSE_DELAYS_LT6_MSB downto REG_MT_COARSE_DELAYS_LT6_LSB);
  coarse_delays(7) <= regs_write_arr(153)(REG_MT_COARSE_DELAYS_LT7_MSB downto REG_MT_COARSE_DELAYS_LT7_LSB);
  coarse_delays(8) <= regs_write_arr(154)(REG_MT_COARSE_DELAYS_LT8_MSB downto REG_MT_COARSE_DELAYS_LT8_LSB);
  coarse_delays(9) <= regs_write_arr(155)(REG_MT_COARSE_DELAYS_LT9_MSB downto REG_MT_COARSE_DELAYS_LT9_LSB);
  coarse_delays(10) <= regs_write_arr(156)(REG_MT_COARSE_DELAYS_LT10_MSB downto REG_MT_COARSE_DELAYS_LT10_LSB);
  coarse_delays(11) <= regs_write_arr(157)(REG_MT_COARSE_DELAYS_LT11_MSB downto REG_MT_COARSE_DELAYS_LT11_LSB);
  coarse_delays(12) <= regs_write_arr(158)(REG_MT_COARSE_DELAYS_LT12_MSB downto REG_MT_COARSE_DELAYS_LT12_LSB);
  coarse_delays(13) <= regs_write_arr(159)(REG_MT_COARSE_DELAYS_LT13_MSB downto REG_MT_COARSE_DELAYS_LT13_LSB);
  coarse_delays(14) <= regs_write_arr(160)(REG_MT_COARSE_DELAYS_LT14_MSB downto REG_MT_COARSE_DELAYS_LT14_LSB);
  coarse_delays(15) <= regs_write_arr(161)(REG_MT_COARSE_DELAYS_LT15_MSB downto REG_MT_COARSE_DELAYS_LT15_LSB);
  coarse_delays(16) <= regs_write_arr(162)(REG_MT_COARSE_DELAYS_LT16_MSB downto REG_MT_COARSE_DELAYS_LT16_LSB);
  coarse_delays(17) <= regs_write_arr(163)(REG_MT_COARSE_DELAYS_LT17_MSB downto REG_MT_COARSE_DELAYS_LT17_LSB);
  coarse_delays(18) <= regs_write_arr(164)(REG_MT_COARSE_DELAYS_LT18_MSB downto REG_MT_COARSE_DELAYS_LT18_LSB);
  coarse_delays(19) <= regs_write_arr(165)(REG_MT_COARSE_DELAYS_LT19_MSB downto REG_MT_COARSE_DELAYS_LT19_LSB);
  coarse_delays(20) <= regs_write_arr(166)(REG_MT_COARSE_DELAYS_LT20_MSB downto REG_MT_COARSE_DELAYS_LT20_LSB);
  coarse_delays(21) <= regs_write_arr(167)(REG_MT_COARSE_DELAYS_LT21_MSB downto REG_MT_COARSE_DELAYS_LT21_LSB);
  coarse_delays(22) <= regs_write_arr(168)(REG_MT_COARSE_DELAYS_LT22_MSB downto REG_MT_COARSE_DELAYS_LT22_LSB);
  coarse_delays(23) <= regs_write_arr(169)(REG_MT_COARSE_DELAYS_LT23_MSB downto REG_MT_COARSE_DELAYS_LT23_LSB);
  coarse_delays(24) <= regs_write_arr(170)(REG_MT_COARSE_DELAYS_LT24_MSB downto REG_MT_COARSE_DELAYS_LT24_LSB);
  coarse_delays(25) <= regs_write_arr(171)(REG_MT_COARSE_DELAYS_LT25_MSB downto REG_MT_COARSE_DELAYS_LT25_LSB);
  coarse_delays(26) <= regs_write_arr(172)(REG_MT_COARSE_DELAYS_LT26_MSB downto REG_MT_COARSE_DELAYS_LT26_LSB);
  coarse_delays(27) <= regs_write_arr(173)(REG_MT_COARSE_DELAYS_LT27_MSB downto REG_MT_COARSE_DELAYS_LT27_LSB);
  coarse_delays(28) <= regs_write_arr(174)(REG_MT_COARSE_DELAYS_LT28_MSB downto REG_MT_COARSE_DELAYS_LT28_LSB);
  coarse_delays(29) <= regs_write_arr(175)(REG_MT_COARSE_DELAYS_LT29_MSB downto REG_MT_COARSE_DELAYS_LT29_LSB);
  coarse_delays(30) <= regs_write_arr(176)(REG_MT_COARSE_DELAYS_LT30_MSB downto REG_MT_COARSE_DELAYS_LT30_LSB);
  coarse_delays(31) <= regs_write_arr(177)(REG_MT_COARSE_DELAYS_LT31_MSB downto REG_MT_COARSE_DELAYS_LT31_LSB);
  coarse_delays(32) <= regs_write_arr(178)(REG_MT_COARSE_DELAYS_LT32_MSB downto REG_MT_COARSE_DELAYS_LT32_LSB);
  coarse_delays(33) <= regs_write_arr(179)(REG_MT_COARSE_DELAYS_LT33_MSB downto REG_MT_COARSE_DELAYS_LT33_LSB);
  coarse_delays(34) <= regs_write_arr(180)(REG_MT_COARSE_DELAYS_LT34_MSB downto REG_MT_COARSE_DELAYS_LT34_LSB);
  coarse_delays(35) <= regs_write_arr(181)(REG_MT_COARSE_DELAYS_LT35_MSB downto REG_MT_COARSE_DELAYS_LT35_LSB);
  coarse_delays(36) <= regs_write_arr(182)(REG_MT_COARSE_DELAYS_LT36_MSB downto REG_MT_COARSE_DELAYS_LT36_LSB);
  coarse_delays(37) <= regs_write_arr(183)(REG_MT_COARSE_DELAYS_LT37_MSB downto REG_MT_COARSE_DELAYS_LT37_LSB);
  coarse_delays(38) <= regs_write_arr(184)(REG_MT_COARSE_DELAYS_LT38_MSB downto REG_MT_COARSE_DELAYS_LT38_LSB);
  coarse_delays(39) <= regs_write_arr(185)(REG_MT_COARSE_DELAYS_LT39_MSB downto REG_MT_COARSE_DELAYS_LT39_LSB);
  coarse_delays(40) <= regs_write_arr(186)(REG_MT_COARSE_DELAYS_LT40_MSB downto REG_MT_COARSE_DELAYS_LT40_LSB);
  coarse_delays(41) <= regs_write_arr(187)(REG_MT_COARSE_DELAYS_LT41_MSB downto REG_MT_COARSE_DELAYS_LT41_LSB);
  coarse_delays(42) <= regs_write_arr(188)(REG_MT_COARSE_DELAYS_LT42_MSB downto REG_MT_COARSE_DELAYS_LT42_LSB);
  coarse_delays(43) <= regs_write_arr(189)(REG_MT_COARSE_DELAYS_LT43_MSB downto REG_MT_COARSE_DELAYS_LT43_LSB);
  coarse_delays(44) <= regs_write_arr(190)(REG_MT_COARSE_DELAYS_LT44_MSB downto REG_MT_COARSE_DELAYS_LT44_LSB);
  coarse_delays(45) <= regs_write_arr(191)(REG_MT_COARSE_DELAYS_LT45_MSB downto REG_MT_COARSE_DELAYS_LT45_LSB);
  coarse_delays(46) <= regs_write_arr(192)(REG_MT_COARSE_DELAYS_LT46_MSB downto REG_MT_COARSE_DELAYS_LT46_LSB);
  coarse_delays(47) <= regs_write_arr(193)(REG_MT_COARSE_DELAYS_LT47_MSB downto REG_MT_COARSE_DELAYS_LT47_LSB);
  coarse_delays(48) <= regs_write_arr(194)(REG_MT_COARSE_DELAYS_LT48_MSB downto REG_MT_COARSE_DELAYS_LT48_LSB);
  coarse_delays(49) <= regs_write_arr(195)(REG_MT_COARSE_DELAYS_LT49_MSB downto REG_MT_COARSE_DELAYS_LT49_LSB);
  coarse_delays(50) <= regs_write_arr(196)(REG_MT_COARSE_DELAYS_LT50_MSB downto REG_MT_COARSE_DELAYS_LT50_LSB);
  coarse_delays(51) <= regs_write_arr(197)(REG_MT_COARSE_DELAYS_LT51_MSB downto REG_MT_COARSE_DELAYS_LT51_LSB);
  coarse_delays(52) <= regs_write_arr(198)(REG_MT_COARSE_DELAYS_LT52_MSB downto REG_MT_COARSE_DELAYS_LT52_LSB);
  coarse_delays(53) <= regs_write_arr(199)(REG_MT_COARSE_DELAYS_LT53_MSB downto REG_MT_COARSE_DELAYS_LT53_LSB);
  coarse_delays(54) <= regs_write_arr(200)(REG_MT_COARSE_DELAYS_LT54_MSB downto REG_MT_COARSE_DELAYS_LT54_LSB);
  coarse_delays(55) <= regs_write_arr(201)(REG_MT_COARSE_DELAYS_LT55_MSB downto REG_MT_COARSE_DELAYS_LT55_LSB);
  coarse_delays(56) <= regs_write_arr(202)(REG_MT_COARSE_DELAYS_LT56_MSB downto REG_MT_COARSE_DELAYS_LT56_LSB);
  coarse_delays(57) <= regs_write_arr(203)(REG_MT_COARSE_DELAYS_LT57_MSB downto REG_MT_COARSE_DELAYS_LT57_LSB);
  coarse_delays(58) <= regs_write_arr(204)(REG_MT_COARSE_DELAYS_LT58_MSB downto REG_MT_COARSE_DELAYS_LT58_LSB);
  coarse_delays(59) <= regs_write_arr(205)(REG_MT_COARSE_DELAYS_LT59_MSB downto REG_MT_COARSE_DELAYS_LT59_LSB);
  coarse_delays(60) <= regs_write_arr(206)(REG_MT_COARSE_DELAYS_LT60_MSB downto REG_MT_COARSE_DELAYS_LT60_LSB);
  coarse_delays(61) <= regs_write_arr(207)(REG_MT_COARSE_DELAYS_LT61_MSB downto REG_MT_COARSE_DELAYS_LT61_LSB);
  coarse_delays(62) <= regs_write_arr(208)(REG_MT_COARSE_DELAYS_LT62_MSB downto REG_MT_COARSE_DELAYS_LT62_LSB);
  coarse_delays(63) <= regs_write_arr(209)(REG_MT_COARSE_DELAYS_LT63_MSB downto REG_MT_COARSE_DELAYS_LT63_LSB);
  coarse_delays(64) <= regs_write_arr(210)(REG_MT_COARSE_DELAYS_LT64_MSB downto REG_MT_COARSE_DELAYS_LT64_LSB);
  coarse_delays(65) <= regs_write_arr(211)(REG_MT_COARSE_DELAYS_LT65_MSB downto REG_MT_COARSE_DELAYS_LT65_LSB);
  coarse_delays(66) <= regs_write_arr(212)(REG_MT_COARSE_DELAYS_LT66_MSB downto REG_MT_COARSE_DELAYS_LT66_LSB);
  coarse_delays(67) <= regs_write_arr(213)(REG_MT_COARSE_DELAYS_LT67_MSB downto REG_MT_COARSE_DELAYS_LT67_LSB);
  coarse_delays(68) <= regs_write_arr(214)(REG_MT_COARSE_DELAYS_LT68_MSB downto REG_MT_COARSE_DELAYS_LT68_LSB);
  coarse_delays(69) <= regs_write_arr(215)(REG_MT_COARSE_DELAYS_LT69_MSB downto REG_MT_COARSE_DELAYS_LT69_LSB);
  coarse_delays(70) <= regs_write_arr(216)(REG_MT_COARSE_DELAYS_LT70_MSB downto REG_MT_COARSE_DELAYS_LT70_LSB);
  coarse_delays(71) <= regs_write_arr(217)(REG_MT_COARSE_DELAYS_LT71_MSB downto REG_MT_COARSE_DELAYS_LT71_LSB);
  coarse_delays(72) <= regs_write_arr(218)(REG_MT_COARSE_DELAYS_LT72_MSB downto REG_MT_COARSE_DELAYS_LT72_LSB);
  coarse_delays(73) <= regs_write_arr(219)(REG_MT_COARSE_DELAYS_LT73_MSB downto REG_MT_COARSE_DELAYS_LT73_LSB);
  coarse_delays(74) <= regs_write_arr(220)(REG_MT_COARSE_DELAYS_LT74_MSB downto REG_MT_COARSE_DELAYS_LT74_LSB);
  posnegs_dsi0 <= regs_write_arr(221)(REG_MT_POSNEGS_DSI0_MSB downto REG_MT_POSNEGS_DSI0_LSB);
  posnegs_dsi1 <= regs_write_arr(222)(REG_MT_POSNEGS_DSI1_MSB downto REG_MT_POSNEGS_DSI1_LSB);
  posnegs_dsi2 <= regs_write_arr(223)(REG_MT_POSNEGS_DSI2_MSB downto REG_MT_POSNEGS_DSI2_LSB);
  posnegs_dsi3 <= regs_write_arr(224)(REG_MT_POSNEGS_DSI3_MSB downto REG_MT_POSNEGS_DSI3_LSB);
  posnegs_dsi4 <= regs_write_arr(225)(REG_MT_POSNEGS_DSI4_MSB downto REG_MT_POSNEGS_DSI4_LSB);

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
  regs_defaults(71)(REG_MT_FINE_DELAYS_LT0_MSB downto REG_MT_FINE_DELAYS_LT0_LSB) <= REG_MT_FINE_DELAYS_LT0_DEFAULT;
  regs_defaults(72)(REG_MT_FINE_DELAYS_LT1_MSB downto REG_MT_FINE_DELAYS_LT1_LSB) <= REG_MT_FINE_DELAYS_LT1_DEFAULT;
  regs_defaults(73)(REG_MT_FINE_DELAYS_LT2_MSB downto REG_MT_FINE_DELAYS_LT2_LSB) <= REG_MT_FINE_DELAYS_LT2_DEFAULT;
  regs_defaults(74)(REG_MT_FINE_DELAYS_LT3_MSB downto REG_MT_FINE_DELAYS_LT3_LSB) <= REG_MT_FINE_DELAYS_LT3_DEFAULT;
  regs_defaults(75)(REG_MT_FINE_DELAYS_LT4_MSB downto REG_MT_FINE_DELAYS_LT4_LSB) <= REG_MT_FINE_DELAYS_LT4_DEFAULT;
  regs_defaults(76)(REG_MT_FINE_DELAYS_LT5_MSB downto REG_MT_FINE_DELAYS_LT5_LSB) <= REG_MT_FINE_DELAYS_LT5_DEFAULT;
  regs_defaults(77)(REG_MT_FINE_DELAYS_LT6_MSB downto REG_MT_FINE_DELAYS_LT6_LSB) <= REG_MT_FINE_DELAYS_LT6_DEFAULT;
  regs_defaults(78)(REG_MT_FINE_DELAYS_LT7_MSB downto REG_MT_FINE_DELAYS_LT7_LSB) <= REG_MT_FINE_DELAYS_LT7_DEFAULT;
  regs_defaults(79)(REG_MT_FINE_DELAYS_LT8_MSB downto REG_MT_FINE_DELAYS_LT8_LSB) <= REG_MT_FINE_DELAYS_LT8_DEFAULT;
  regs_defaults(80)(REG_MT_FINE_DELAYS_LT9_MSB downto REG_MT_FINE_DELAYS_LT9_LSB) <= REG_MT_FINE_DELAYS_LT9_DEFAULT;
  regs_defaults(81)(REG_MT_FINE_DELAYS_LT10_MSB downto REG_MT_FINE_DELAYS_LT10_LSB) <= REG_MT_FINE_DELAYS_LT10_DEFAULT;
  regs_defaults(82)(REG_MT_FINE_DELAYS_LT11_MSB downto REG_MT_FINE_DELAYS_LT11_LSB) <= REG_MT_FINE_DELAYS_LT11_DEFAULT;
  regs_defaults(83)(REG_MT_FINE_DELAYS_LT12_MSB downto REG_MT_FINE_DELAYS_LT12_LSB) <= REG_MT_FINE_DELAYS_LT12_DEFAULT;
  regs_defaults(84)(REG_MT_FINE_DELAYS_LT13_MSB downto REG_MT_FINE_DELAYS_LT13_LSB) <= REG_MT_FINE_DELAYS_LT13_DEFAULT;
  regs_defaults(85)(REG_MT_FINE_DELAYS_LT14_MSB downto REG_MT_FINE_DELAYS_LT14_LSB) <= REG_MT_FINE_DELAYS_LT14_DEFAULT;
  regs_defaults(86)(REG_MT_FINE_DELAYS_LT15_MSB downto REG_MT_FINE_DELAYS_LT15_LSB) <= REG_MT_FINE_DELAYS_LT15_DEFAULT;
  regs_defaults(87)(REG_MT_FINE_DELAYS_LT16_MSB downto REG_MT_FINE_DELAYS_LT16_LSB) <= REG_MT_FINE_DELAYS_LT16_DEFAULT;
  regs_defaults(88)(REG_MT_FINE_DELAYS_LT17_MSB downto REG_MT_FINE_DELAYS_LT17_LSB) <= REG_MT_FINE_DELAYS_LT17_DEFAULT;
  regs_defaults(89)(REG_MT_FINE_DELAYS_LT18_MSB downto REG_MT_FINE_DELAYS_LT18_LSB) <= REG_MT_FINE_DELAYS_LT18_DEFAULT;
  regs_defaults(90)(REG_MT_FINE_DELAYS_LT19_MSB downto REG_MT_FINE_DELAYS_LT19_LSB) <= REG_MT_FINE_DELAYS_LT19_DEFAULT;
  regs_defaults(91)(REG_MT_FINE_DELAYS_LT20_MSB downto REG_MT_FINE_DELAYS_LT20_LSB) <= REG_MT_FINE_DELAYS_LT20_DEFAULT;
  regs_defaults(92)(REG_MT_FINE_DELAYS_LT21_MSB downto REG_MT_FINE_DELAYS_LT21_LSB) <= REG_MT_FINE_DELAYS_LT21_DEFAULT;
  regs_defaults(93)(REG_MT_FINE_DELAYS_LT22_MSB downto REG_MT_FINE_DELAYS_LT22_LSB) <= REG_MT_FINE_DELAYS_LT22_DEFAULT;
  regs_defaults(94)(REG_MT_FINE_DELAYS_LT23_MSB downto REG_MT_FINE_DELAYS_LT23_LSB) <= REG_MT_FINE_DELAYS_LT23_DEFAULT;
  regs_defaults(95)(REG_MT_FINE_DELAYS_LT24_MSB downto REG_MT_FINE_DELAYS_LT24_LSB) <= REG_MT_FINE_DELAYS_LT24_DEFAULT;
  regs_defaults(96)(REG_MT_FINE_DELAYS_LT25_MSB downto REG_MT_FINE_DELAYS_LT25_LSB) <= REG_MT_FINE_DELAYS_LT25_DEFAULT;
  regs_defaults(97)(REG_MT_FINE_DELAYS_LT26_MSB downto REG_MT_FINE_DELAYS_LT26_LSB) <= REG_MT_FINE_DELAYS_LT26_DEFAULT;
  regs_defaults(98)(REG_MT_FINE_DELAYS_LT27_MSB downto REG_MT_FINE_DELAYS_LT27_LSB) <= REG_MT_FINE_DELAYS_LT27_DEFAULT;
  regs_defaults(99)(REG_MT_FINE_DELAYS_LT28_MSB downto REG_MT_FINE_DELAYS_LT28_LSB) <= REG_MT_FINE_DELAYS_LT28_DEFAULT;
  regs_defaults(100)(REG_MT_FINE_DELAYS_LT29_MSB downto REG_MT_FINE_DELAYS_LT29_LSB) <= REG_MT_FINE_DELAYS_LT29_DEFAULT;
  regs_defaults(101)(REG_MT_FINE_DELAYS_LT30_MSB downto REG_MT_FINE_DELAYS_LT30_LSB) <= REG_MT_FINE_DELAYS_LT30_DEFAULT;
  regs_defaults(102)(REG_MT_FINE_DELAYS_LT31_MSB downto REG_MT_FINE_DELAYS_LT31_LSB) <= REG_MT_FINE_DELAYS_LT31_DEFAULT;
  regs_defaults(103)(REG_MT_FINE_DELAYS_LT32_MSB downto REG_MT_FINE_DELAYS_LT32_LSB) <= REG_MT_FINE_DELAYS_LT32_DEFAULT;
  regs_defaults(104)(REG_MT_FINE_DELAYS_LT33_MSB downto REG_MT_FINE_DELAYS_LT33_LSB) <= REG_MT_FINE_DELAYS_LT33_DEFAULT;
  regs_defaults(105)(REG_MT_FINE_DELAYS_LT34_MSB downto REG_MT_FINE_DELAYS_LT34_LSB) <= REG_MT_FINE_DELAYS_LT34_DEFAULT;
  regs_defaults(106)(REG_MT_FINE_DELAYS_LT35_MSB downto REG_MT_FINE_DELAYS_LT35_LSB) <= REG_MT_FINE_DELAYS_LT35_DEFAULT;
  regs_defaults(107)(REG_MT_FINE_DELAYS_LT36_MSB downto REG_MT_FINE_DELAYS_LT36_LSB) <= REG_MT_FINE_DELAYS_LT36_DEFAULT;
  regs_defaults(108)(REG_MT_FINE_DELAYS_LT37_MSB downto REG_MT_FINE_DELAYS_LT37_LSB) <= REG_MT_FINE_DELAYS_LT37_DEFAULT;
  regs_defaults(109)(REG_MT_FINE_DELAYS_LT38_MSB downto REG_MT_FINE_DELAYS_LT38_LSB) <= REG_MT_FINE_DELAYS_LT38_DEFAULT;
  regs_defaults(110)(REG_MT_FINE_DELAYS_LT39_MSB downto REG_MT_FINE_DELAYS_LT39_LSB) <= REG_MT_FINE_DELAYS_LT39_DEFAULT;
  regs_defaults(111)(REG_MT_FINE_DELAYS_LT40_MSB downto REG_MT_FINE_DELAYS_LT40_LSB) <= REG_MT_FINE_DELAYS_LT40_DEFAULT;
  regs_defaults(112)(REG_MT_FINE_DELAYS_LT41_MSB downto REG_MT_FINE_DELAYS_LT41_LSB) <= REG_MT_FINE_DELAYS_LT41_DEFAULT;
  regs_defaults(113)(REG_MT_FINE_DELAYS_LT42_MSB downto REG_MT_FINE_DELAYS_LT42_LSB) <= REG_MT_FINE_DELAYS_LT42_DEFAULT;
  regs_defaults(114)(REG_MT_FINE_DELAYS_LT43_MSB downto REG_MT_FINE_DELAYS_LT43_LSB) <= REG_MT_FINE_DELAYS_LT43_DEFAULT;
  regs_defaults(115)(REG_MT_FINE_DELAYS_LT44_MSB downto REG_MT_FINE_DELAYS_LT44_LSB) <= REG_MT_FINE_DELAYS_LT44_DEFAULT;
  regs_defaults(116)(REG_MT_FINE_DELAYS_LT45_MSB downto REG_MT_FINE_DELAYS_LT45_LSB) <= REG_MT_FINE_DELAYS_LT45_DEFAULT;
  regs_defaults(117)(REG_MT_FINE_DELAYS_LT46_MSB downto REG_MT_FINE_DELAYS_LT46_LSB) <= REG_MT_FINE_DELAYS_LT46_DEFAULT;
  regs_defaults(118)(REG_MT_FINE_DELAYS_LT47_MSB downto REG_MT_FINE_DELAYS_LT47_LSB) <= REG_MT_FINE_DELAYS_LT47_DEFAULT;
  regs_defaults(119)(REG_MT_FINE_DELAYS_LT48_MSB downto REG_MT_FINE_DELAYS_LT48_LSB) <= REG_MT_FINE_DELAYS_LT48_DEFAULT;
  regs_defaults(120)(REG_MT_FINE_DELAYS_LT49_MSB downto REG_MT_FINE_DELAYS_LT49_LSB) <= REG_MT_FINE_DELAYS_LT49_DEFAULT;
  regs_defaults(121)(REG_MT_FINE_DELAYS_LT50_MSB downto REG_MT_FINE_DELAYS_LT50_LSB) <= REG_MT_FINE_DELAYS_LT50_DEFAULT;
  regs_defaults(122)(REG_MT_FINE_DELAYS_LT51_MSB downto REG_MT_FINE_DELAYS_LT51_LSB) <= REG_MT_FINE_DELAYS_LT51_DEFAULT;
  regs_defaults(123)(REG_MT_FINE_DELAYS_LT52_MSB downto REG_MT_FINE_DELAYS_LT52_LSB) <= REG_MT_FINE_DELAYS_LT52_DEFAULT;
  regs_defaults(124)(REG_MT_FINE_DELAYS_LT53_MSB downto REG_MT_FINE_DELAYS_LT53_LSB) <= REG_MT_FINE_DELAYS_LT53_DEFAULT;
  regs_defaults(125)(REG_MT_FINE_DELAYS_LT54_MSB downto REG_MT_FINE_DELAYS_LT54_LSB) <= REG_MT_FINE_DELAYS_LT54_DEFAULT;
  regs_defaults(126)(REG_MT_FINE_DELAYS_LT55_MSB downto REG_MT_FINE_DELAYS_LT55_LSB) <= REG_MT_FINE_DELAYS_LT55_DEFAULT;
  regs_defaults(127)(REG_MT_FINE_DELAYS_LT56_MSB downto REG_MT_FINE_DELAYS_LT56_LSB) <= REG_MT_FINE_DELAYS_LT56_DEFAULT;
  regs_defaults(128)(REG_MT_FINE_DELAYS_LT57_MSB downto REG_MT_FINE_DELAYS_LT57_LSB) <= REG_MT_FINE_DELAYS_LT57_DEFAULT;
  regs_defaults(129)(REG_MT_FINE_DELAYS_LT58_MSB downto REG_MT_FINE_DELAYS_LT58_LSB) <= REG_MT_FINE_DELAYS_LT58_DEFAULT;
  regs_defaults(130)(REG_MT_FINE_DELAYS_LT59_MSB downto REG_MT_FINE_DELAYS_LT59_LSB) <= REG_MT_FINE_DELAYS_LT59_DEFAULT;
  regs_defaults(131)(REG_MT_FINE_DELAYS_LT60_MSB downto REG_MT_FINE_DELAYS_LT60_LSB) <= REG_MT_FINE_DELAYS_LT60_DEFAULT;
  regs_defaults(132)(REG_MT_FINE_DELAYS_LT61_MSB downto REG_MT_FINE_DELAYS_LT61_LSB) <= REG_MT_FINE_DELAYS_LT61_DEFAULT;
  regs_defaults(133)(REG_MT_FINE_DELAYS_LT62_MSB downto REG_MT_FINE_DELAYS_LT62_LSB) <= REG_MT_FINE_DELAYS_LT62_DEFAULT;
  regs_defaults(134)(REG_MT_FINE_DELAYS_LT63_MSB downto REG_MT_FINE_DELAYS_LT63_LSB) <= REG_MT_FINE_DELAYS_LT63_DEFAULT;
  regs_defaults(135)(REG_MT_FINE_DELAYS_LT64_MSB downto REG_MT_FINE_DELAYS_LT64_LSB) <= REG_MT_FINE_DELAYS_LT64_DEFAULT;
  regs_defaults(136)(REG_MT_FINE_DELAYS_LT65_MSB downto REG_MT_FINE_DELAYS_LT65_LSB) <= REG_MT_FINE_DELAYS_LT65_DEFAULT;
  regs_defaults(137)(REG_MT_FINE_DELAYS_LT66_MSB downto REG_MT_FINE_DELAYS_LT66_LSB) <= REG_MT_FINE_DELAYS_LT66_DEFAULT;
  regs_defaults(138)(REG_MT_FINE_DELAYS_LT67_MSB downto REG_MT_FINE_DELAYS_LT67_LSB) <= REG_MT_FINE_DELAYS_LT67_DEFAULT;
  regs_defaults(139)(REG_MT_FINE_DELAYS_LT68_MSB downto REG_MT_FINE_DELAYS_LT68_LSB) <= REG_MT_FINE_DELAYS_LT68_DEFAULT;
  regs_defaults(140)(REG_MT_FINE_DELAYS_LT69_MSB downto REG_MT_FINE_DELAYS_LT69_LSB) <= REG_MT_FINE_DELAYS_LT69_DEFAULT;
  regs_defaults(141)(REG_MT_FINE_DELAYS_LT70_MSB downto REG_MT_FINE_DELAYS_LT70_LSB) <= REG_MT_FINE_DELAYS_LT70_DEFAULT;
  regs_defaults(142)(REG_MT_FINE_DELAYS_LT71_MSB downto REG_MT_FINE_DELAYS_LT71_LSB) <= REG_MT_FINE_DELAYS_LT71_DEFAULT;
  regs_defaults(143)(REG_MT_FINE_DELAYS_LT72_MSB downto REG_MT_FINE_DELAYS_LT72_LSB) <= REG_MT_FINE_DELAYS_LT72_DEFAULT;
  regs_defaults(144)(REG_MT_FINE_DELAYS_LT73_MSB downto REG_MT_FINE_DELAYS_LT73_LSB) <= REG_MT_FINE_DELAYS_LT73_DEFAULT;
  regs_defaults(145)(REG_MT_FINE_DELAYS_LT74_MSB downto REG_MT_FINE_DELAYS_LT74_LSB) <= REG_MT_FINE_DELAYS_LT74_DEFAULT;
  regs_defaults(146)(REG_MT_COARSE_DELAYS_LT0_MSB downto REG_MT_COARSE_DELAYS_LT0_LSB) <= REG_MT_COARSE_DELAYS_LT0_DEFAULT;
  regs_defaults(147)(REG_MT_COARSE_DELAYS_LT1_MSB downto REG_MT_COARSE_DELAYS_LT1_LSB) <= REG_MT_COARSE_DELAYS_LT1_DEFAULT;
  regs_defaults(148)(REG_MT_COARSE_DELAYS_LT2_MSB downto REG_MT_COARSE_DELAYS_LT2_LSB) <= REG_MT_COARSE_DELAYS_LT2_DEFAULT;
  regs_defaults(149)(REG_MT_COARSE_DELAYS_LT3_MSB downto REG_MT_COARSE_DELAYS_LT3_LSB) <= REG_MT_COARSE_DELAYS_LT3_DEFAULT;
  regs_defaults(150)(REG_MT_COARSE_DELAYS_LT4_MSB downto REG_MT_COARSE_DELAYS_LT4_LSB) <= REG_MT_COARSE_DELAYS_LT4_DEFAULT;
  regs_defaults(151)(REG_MT_COARSE_DELAYS_LT5_MSB downto REG_MT_COARSE_DELAYS_LT5_LSB) <= REG_MT_COARSE_DELAYS_LT5_DEFAULT;
  regs_defaults(152)(REG_MT_COARSE_DELAYS_LT6_MSB downto REG_MT_COARSE_DELAYS_LT6_LSB) <= REG_MT_COARSE_DELAYS_LT6_DEFAULT;
  regs_defaults(153)(REG_MT_COARSE_DELAYS_LT7_MSB downto REG_MT_COARSE_DELAYS_LT7_LSB) <= REG_MT_COARSE_DELAYS_LT7_DEFAULT;
  regs_defaults(154)(REG_MT_COARSE_DELAYS_LT8_MSB downto REG_MT_COARSE_DELAYS_LT8_LSB) <= REG_MT_COARSE_DELAYS_LT8_DEFAULT;
  regs_defaults(155)(REG_MT_COARSE_DELAYS_LT9_MSB downto REG_MT_COARSE_DELAYS_LT9_LSB) <= REG_MT_COARSE_DELAYS_LT9_DEFAULT;
  regs_defaults(156)(REG_MT_COARSE_DELAYS_LT10_MSB downto REG_MT_COARSE_DELAYS_LT10_LSB) <= REG_MT_COARSE_DELAYS_LT10_DEFAULT;
  regs_defaults(157)(REG_MT_COARSE_DELAYS_LT11_MSB downto REG_MT_COARSE_DELAYS_LT11_LSB) <= REG_MT_COARSE_DELAYS_LT11_DEFAULT;
  regs_defaults(158)(REG_MT_COARSE_DELAYS_LT12_MSB downto REG_MT_COARSE_DELAYS_LT12_LSB) <= REG_MT_COARSE_DELAYS_LT12_DEFAULT;
  regs_defaults(159)(REG_MT_COARSE_DELAYS_LT13_MSB downto REG_MT_COARSE_DELAYS_LT13_LSB) <= REG_MT_COARSE_DELAYS_LT13_DEFAULT;
  regs_defaults(160)(REG_MT_COARSE_DELAYS_LT14_MSB downto REG_MT_COARSE_DELAYS_LT14_LSB) <= REG_MT_COARSE_DELAYS_LT14_DEFAULT;
  regs_defaults(161)(REG_MT_COARSE_DELAYS_LT15_MSB downto REG_MT_COARSE_DELAYS_LT15_LSB) <= REG_MT_COARSE_DELAYS_LT15_DEFAULT;
  regs_defaults(162)(REG_MT_COARSE_DELAYS_LT16_MSB downto REG_MT_COARSE_DELAYS_LT16_LSB) <= REG_MT_COARSE_DELAYS_LT16_DEFAULT;
  regs_defaults(163)(REG_MT_COARSE_DELAYS_LT17_MSB downto REG_MT_COARSE_DELAYS_LT17_LSB) <= REG_MT_COARSE_DELAYS_LT17_DEFAULT;
  regs_defaults(164)(REG_MT_COARSE_DELAYS_LT18_MSB downto REG_MT_COARSE_DELAYS_LT18_LSB) <= REG_MT_COARSE_DELAYS_LT18_DEFAULT;
  regs_defaults(165)(REG_MT_COARSE_DELAYS_LT19_MSB downto REG_MT_COARSE_DELAYS_LT19_LSB) <= REG_MT_COARSE_DELAYS_LT19_DEFAULT;
  regs_defaults(166)(REG_MT_COARSE_DELAYS_LT20_MSB downto REG_MT_COARSE_DELAYS_LT20_LSB) <= REG_MT_COARSE_DELAYS_LT20_DEFAULT;
  regs_defaults(167)(REG_MT_COARSE_DELAYS_LT21_MSB downto REG_MT_COARSE_DELAYS_LT21_LSB) <= REG_MT_COARSE_DELAYS_LT21_DEFAULT;
  regs_defaults(168)(REG_MT_COARSE_DELAYS_LT22_MSB downto REG_MT_COARSE_DELAYS_LT22_LSB) <= REG_MT_COARSE_DELAYS_LT22_DEFAULT;
  regs_defaults(169)(REG_MT_COARSE_DELAYS_LT23_MSB downto REG_MT_COARSE_DELAYS_LT23_LSB) <= REG_MT_COARSE_DELAYS_LT23_DEFAULT;
  regs_defaults(170)(REG_MT_COARSE_DELAYS_LT24_MSB downto REG_MT_COARSE_DELAYS_LT24_LSB) <= REG_MT_COARSE_DELAYS_LT24_DEFAULT;
  regs_defaults(171)(REG_MT_COARSE_DELAYS_LT25_MSB downto REG_MT_COARSE_DELAYS_LT25_LSB) <= REG_MT_COARSE_DELAYS_LT25_DEFAULT;
  regs_defaults(172)(REG_MT_COARSE_DELAYS_LT26_MSB downto REG_MT_COARSE_DELAYS_LT26_LSB) <= REG_MT_COARSE_DELAYS_LT26_DEFAULT;
  regs_defaults(173)(REG_MT_COARSE_DELAYS_LT27_MSB downto REG_MT_COARSE_DELAYS_LT27_LSB) <= REG_MT_COARSE_DELAYS_LT27_DEFAULT;
  regs_defaults(174)(REG_MT_COARSE_DELAYS_LT28_MSB downto REG_MT_COARSE_DELAYS_LT28_LSB) <= REG_MT_COARSE_DELAYS_LT28_DEFAULT;
  regs_defaults(175)(REG_MT_COARSE_DELAYS_LT29_MSB downto REG_MT_COARSE_DELAYS_LT29_LSB) <= REG_MT_COARSE_DELAYS_LT29_DEFAULT;
  regs_defaults(176)(REG_MT_COARSE_DELAYS_LT30_MSB downto REG_MT_COARSE_DELAYS_LT30_LSB) <= REG_MT_COARSE_DELAYS_LT30_DEFAULT;
  regs_defaults(177)(REG_MT_COARSE_DELAYS_LT31_MSB downto REG_MT_COARSE_DELAYS_LT31_LSB) <= REG_MT_COARSE_DELAYS_LT31_DEFAULT;
  regs_defaults(178)(REG_MT_COARSE_DELAYS_LT32_MSB downto REG_MT_COARSE_DELAYS_LT32_LSB) <= REG_MT_COARSE_DELAYS_LT32_DEFAULT;
  regs_defaults(179)(REG_MT_COARSE_DELAYS_LT33_MSB downto REG_MT_COARSE_DELAYS_LT33_LSB) <= REG_MT_COARSE_DELAYS_LT33_DEFAULT;
  regs_defaults(180)(REG_MT_COARSE_DELAYS_LT34_MSB downto REG_MT_COARSE_DELAYS_LT34_LSB) <= REG_MT_COARSE_DELAYS_LT34_DEFAULT;
  regs_defaults(181)(REG_MT_COARSE_DELAYS_LT35_MSB downto REG_MT_COARSE_DELAYS_LT35_LSB) <= REG_MT_COARSE_DELAYS_LT35_DEFAULT;
  regs_defaults(182)(REG_MT_COARSE_DELAYS_LT36_MSB downto REG_MT_COARSE_DELAYS_LT36_LSB) <= REG_MT_COARSE_DELAYS_LT36_DEFAULT;
  regs_defaults(183)(REG_MT_COARSE_DELAYS_LT37_MSB downto REG_MT_COARSE_DELAYS_LT37_LSB) <= REG_MT_COARSE_DELAYS_LT37_DEFAULT;
  regs_defaults(184)(REG_MT_COARSE_DELAYS_LT38_MSB downto REG_MT_COARSE_DELAYS_LT38_LSB) <= REG_MT_COARSE_DELAYS_LT38_DEFAULT;
  regs_defaults(185)(REG_MT_COARSE_DELAYS_LT39_MSB downto REG_MT_COARSE_DELAYS_LT39_LSB) <= REG_MT_COARSE_DELAYS_LT39_DEFAULT;
  regs_defaults(186)(REG_MT_COARSE_DELAYS_LT40_MSB downto REG_MT_COARSE_DELAYS_LT40_LSB) <= REG_MT_COARSE_DELAYS_LT40_DEFAULT;
  regs_defaults(187)(REG_MT_COARSE_DELAYS_LT41_MSB downto REG_MT_COARSE_DELAYS_LT41_LSB) <= REG_MT_COARSE_DELAYS_LT41_DEFAULT;
  regs_defaults(188)(REG_MT_COARSE_DELAYS_LT42_MSB downto REG_MT_COARSE_DELAYS_LT42_LSB) <= REG_MT_COARSE_DELAYS_LT42_DEFAULT;
  regs_defaults(189)(REG_MT_COARSE_DELAYS_LT43_MSB downto REG_MT_COARSE_DELAYS_LT43_LSB) <= REG_MT_COARSE_DELAYS_LT43_DEFAULT;
  regs_defaults(190)(REG_MT_COARSE_DELAYS_LT44_MSB downto REG_MT_COARSE_DELAYS_LT44_LSB) <= REG_MT_COARSE_DELAYS_LT44_DEFAULT;
  regs_defaults(191)(REG_MT_COARSE_DELAYS_LT45_MSB downto REG_MT_COARSE_DELAYS_LT45_LSB) <= REG_MT_COARSE_DELAYS_LT45_DEFAULT;
  regs_defaults(192)(REG_MT_COARSE_DELAYS_LT46_MSB downto REG_MT_COARSE_DELAYS_LT46_LSB) <= REG_MT_COARSE_DELAYS_LT46_DEFAULT;
  regs_defaults(193)(REG_MT_COARSE_DELAYS_LT47_MSB downto REG_MT_COARSE_DELAYS_LT47_LSB) <= REG_MT_COARSE_DELAYS_LT47_DEFAULT;
  regs_defaults(194)(REG_MT_COARSE_DELAYS_LT48_MSB downto REG_MT_COARSE_DELAYS_LT48_LSB) <= REG_MT_COARSE_DELAYS_LT48_DEFAULT;
  regs_defaults(195)(REG_MT_COARSE_DELAYS_LT49_MSB downto REG_MT_COARSE_DELAYS_LT49_LSB) <= REG_MT_COARSE_DELAYS_LT49_DEFAULT;
  regs_defaults(196)(REG_MT_COARSE_DELAYS_LT50_MSB downto REG_MT_COARSE_DELAYS_LT50_LSB) <= REG_MT_COARSE_DELAYS_LT50_DEFAULT;
  regs_defaults(197)(REG_MT_COARSE_DELAYS_LT51_MSB downto REG_MT_COARSE_DELAYS_LT51_LSB) <= REG_MT_COARSE_DELAYS_LT51_DEFAULT;
  regs_defaults(198)(REG_MT_COARSE_DELAYS_LT52_MSB downto REG_MT_COARSE_DELAYS_LT52_LSB) <= REG_MT_COARSE_DELAYS_LT52_DEFAULT;
  regs_defaults(199)(REG_MT_COARSE_DELAYS_LT53_MSB downto REG_MT_COARSE_DELAYS_LT53_LSB) <= REG_MT_COARSE_DELAYS_LT53_DEFAULT;
  regs_defaults(200)(REG_MT_COARSE_DELAYS_LT54_MSB downto REG_MT_COARSE_DELAYS_LT54_LSB) <= REG_MT_COARSE_DELAYS_LT54_DEFAULT;
  regs_defaults(201)(REG_MT_COARSE_DELAYS_LT55_MSB downto REG_MT_COARSE_DELAYS_LT55_LSB) <= REG_MT_COARSE_DELAYS_LT55_DEFAULT;
  regs_defaults(202)(REG_MT_COARSE_DELAYS_LT56_MSB downto REG_MT_COARSE_DELAYS_LT56_LSB) <= REG_MT_COARSE_DELAYS_LT56_DEFAULT;
  regs_defaults(203)(REG_MT_COARSE_DELAYS_LT57_MSB downto REG_MT_COARSE_DELAYS_LT57_LSB) <= REG_MT_COARSE_DELAYS_LT57_DEFAULT;
  regs_defaults(204)(REG_MT_COARSE_DELAYS_LT58_MSB downto REG_MT_COARSE_DELAYS_LT58_LSB) <= REG_MT_COARSE_DELAYS_LT58_DEFAULT;
  regs_defaults(205)(REG_MT_COARSE_DELAYS_LT59_MSB downto REG_MT_COARSE_DELAYS_LT59_LSB) <= REG_MT_COARSE_DELAYS_LT59_DEFAULT;
  regs_defaults(206)(REG_MT_COARSE_DELAYS_LT60_MSB downto REG_MT_COARSE_DELAYS_LT60_LSB) <= REG_MT_COARSE_DELAYS_LT60_DEFAULT;
  regs_defaults(207)(REG_MT_COARSE_DELAYS_LT61_MSB downto REG_MT_COARSE_DELAYS_LT61_LSB) <= REG_MT_COARSE_DELAYS_LT61_DEFAULT;
  regs_defaults(208)(REG_MT_COARSE_DELAYS_LT62_MSB downto REG_MT_COARSE_DELAYS_LT62_LSB) <= REG_MT_COARSE_DELAYS_LT62_DEFAULT;
  regs_defaults(209)(REG_MT_COARSE_DELAYS_LT63_MSB downto REG_MT_COARSE_DELAYS_LT63_LSB) <= REG_MT_COARSE_DELAYS_LT63_DEFAULT;
  regs_defaults(210)(REG_MT_COARSE_DELAYS_LT64_MSB downto REG_MT_COARSE_DELAYS_LT64_LSB) <= REG_MT_COARSE_DELAYS_LT64_DEFAULT;
  regs_defaults(211)(REG_MT_COARSE_DELAYS_LT65_MSB downto REG_MT_COARSE_DELAYS_LT65_LSB) <= REG_MT_COARSE_DELAYS_LT65_DEFAULT;
  regs_defaults(212)(REG_MT_COARSE_DELAYS_LT66_MSB downto REG_MT_COARSE_DELAYS_LT66_LSB) <= REG_MT_COARSE_DELAYS_LT66_DEFAULT;
  regs_defaults(213)(REG_MT_COARSE_DELAYS_LT67_MSB downto REG_MT_COARSE_DELAYS_LT67_LSB) <= REG_MT_COARSE_DELAYS_LT67_DEFAULT;
  regs_defaults(214)(REG_MT_COARSE_DELAYS_LT68_MSB downto REG_MT_COARSE_DELAYS_LT68_LSB) <= REG_MT_COARSE_DELAYS_LT68_DEFAULT;
  regs_defaults(215)(REG_MT_COARSE_DELAYS_LT69_MSB downto REG_MT_COARSE_DELAYS_LT69_LSB) <= REG_MT_COARSE_DELAYS_LT69_DEFAULT;
  regs_defaults(216)(REG_MT_COARSE_DELAYS_LT70_MSB downto REG_MT_COARSE_DELAYS_LT70_LSB) <= REG_MT_COARSE_DELAYS_LT70_DEFAULT;
  regs_defaults(217)(REG_MT_COARSE_DELAYS_LT71_MSB downto REG_MT_COARSE_DELAYS_LT71_LSB) <= REG_MT_COARSE_DELAYS_LT71_DEFAULT;
  regs_defaults(218)(REG_MT_COARSE_DELAYS_LT72_MSB downto REG_MT_COARSE_DELAYS_LT72_LSB) <= REG_MT_COARSE_DELAYS_LT72_DEFAULT;
  regs_defaults(219)(REG_MT_COARSE_DELAYS_LT73_MSB downto REG_MT_COARSE_DELAYS_LT73_LSB) <= REG_MT_COARSE_DELAYS_LT73_DEFAULT;
  regs_defaults(220)(REG_MT_COARSE_DELAYS_LT74_MSB downto REG_MT_COARSE_DELAYS_LT74_LSB) <= REG_MT_COARSE_DELAYS_LT74_DEFAULT;
  regs_defaults(221)(REG_MT_POSNEGS_DSI0_MSB downto REG_MT_POSNEGS_DSI0_LSB) <= REG_MT_POSNEGS_DSI0_DEFAULT;
  regs_defaults(222)(REG_MT_POSNEGS_DSI1_MSB downto REG_MT_POSNEGS_DSI1_LSB) <= REG_MT_POSNEGS_DSI1_DEFAULT;
  regs_defaults(223)(REG_MT_POSNEGS_DSI2_MSB downto REG_MT_POSNEGS_DSI2_LSB) <= REG_MT_POSNEGS_DSI2_DEFAULT;
  regs_defaults(224)(REG_MT_POSNEGS_DSI3_MSB downto REG_MT_POSNEGS_DSI3_LSB) <= REG_MT_POSNEGS_DSI3_DEFAULT;
  regs_defaults(225)(REG_MT_POSNEGS_DSI4_MSB downto REG_MT_POSNEGS_DSI4_LSB) <= REG_MT_POSNEGS_DSI4_DEFAULT;

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
  regs_writable_arr(131) <= '1';
  regs_writable_arr(132) <= '1';
  regs_writable_arr(133) <= '1';
  regs_writable_arr(134) <= '1';
  regs_writable_arr(135) <= '1';
  regs_writable_arr(136) <= '1';
  regs_writable_arr(137) <= '1';
  regs_writable_arr(138) <= '1';
  regs_writable_arr(139) <= '1';
  regs_writable_arr(140) <= '1';
  regs_writable_arr(141) <= '1';
  regs_writable_arr(142) <= '1';
  regs_writable_arr(143) <= '1';
  regs_writable_arr(144) <= '1';
  regs_writable_arr(145) <= '1';
  regs_writable_arr(146) <= '1';
  regs_writable_arr(147) <= '1';
  regs_writable_arr(148) <= '1';
  regs_writable_arr(149) <= '1';
  regs_writable_arr(150) <= '1';
  regs_writable_arr(151) <= '1';
  regs_writable_arr(152) <= '1';
  regs_writable_arr(153) <= '1';
  regs_writable_arr(154) <= '1';
  regs_writable_arr(155) <= '1';
  regs_writable_arr(156) <= '1';
  regs_writable_arr(157) <= '1';
  regs_writable_arr(158) <= '1';
  regs_writable_arr(159) <= '1';
  regs_writable_arr(160) <= '1';
  regs_writable_arr(161) <= '1';
  regs_writable_arr(162) <= '1';
  regs_writable_arr(163) <= '1';
  regs_writable_arr(164) <= '1';
  regs_writable_arr(165) <= '1';
  regs_writable_arr(166) <= '1';
  regs_writable_arr(167) <= '1';
  regs_writable_arr(168) <= '1';
  regs_writable_arr(169) <= '1';
  regs_writable_arr(170) <= '1';
  regs_writable_arr(171) <= '1';
  regs_writable_arr(172) <= '1';
  regs_writable_arr(173) <= '1';
  regs_writable_arr(174) <= '1';
  regs_writable_arr(175) <= '1';
  regs_writable_arr(176) <= '1';
  regs_writable_arr(177) <= '1';
  regs_writable_arr(178) <= '1';
  regs_writable_arr(179) <= '1';
  regs_writable_arr(180) <= '1';
  regs_writable_arr(181) <= '1';
  regs_writable_arr(182) <= '1';
  regs_writable_arr(183) <= '1';
  regs_writable_arr(184) <= '1';
  regs_writable_arr(185) <= '1';
  regs_writable_arr(186) <= '1';
  regs_writable_arr(187) <= '1';
  regs_writable_arr(188) <= '1';
  regs_writable_arr(189) <= '1';
  regs_writable_arr(190) <= '1';
  regs_writable_arr(191) <= '1';
  regs_writable_arr(192) <= '1';
  regs_writable_arr(193) <= '1';
  regs_writable_arr(194) <= '1';
  regs_writable_arr(195) <= '1';
  regs_writable_arr(196) <= '1';
  regs_writable_arr(197) <= '1';
  regs_writable_arr(198) <= '1';
  regs_writable_arr(199) <= '1';
  regs_writable_arr(200) <= '1';
  regs_writable_arr(201) <= '1';
  regs_writable_arr(202) <= '1';
  regs_writable_arr(203) <= '1';
  regs_writable_arr(204) <= '1';
  regs_writable_arr(205) <= '1';
  regs_writable_arr(206) <= '1';
  regs_writable_arr(207) <= '1';
  regs_writable_arr(208) <= '1';
  regs_writable_arr(209) <= '1';
  regs_writable_arr(210) <= '1';
  regs_writable_arr(211) <= '1';
  regs_writable_arr(212) <= '1';
  regs_writable_arr(213) <= '1';
  regs_writable_arr(214) <= '1';
  regs_writable_arr(215) <= '1';
  regs_writable_arr(216) <= '1';
  regs_writable_arr(217) <= '1';
  regs_writable_arr(218) <= '1';
  regs_writable_arr(219) <= '1';
  regs_writable_arr(220) <= '1';
  regs_writable_arr(221) <= '1';
  regs_writable_arr(222) <= '1';
  regs_writable_arr(223) <= '1';
  regs_writable_arr(224) <= '1';
  regs_writable_arr(225) <= '1';

--==== Registers end ============================================================================
end structural;
