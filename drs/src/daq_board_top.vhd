----------------------------------------------------------------------------------
-- DRS DAQ Board Top
-- GAPS DRS4 Readout Firmware
-- I. Garcia, A. Peck, S. Quinn, T. Hayashi
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.ipbus.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;
use work.components.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity top_readout_board is
  generic (
    EN_TMR_IPB_SLAVE_DRS : integer := 0;

    DEBUG : boolean := false;

    CLK_FREQUENCY : integer := 33000000;

    -- these generics get set by hog at synthesis
    GLOBAL_DATE : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_TIME : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_VER  : std_logic_vector (31 downto 0) := x"00000000";
    GLOBAL_SHA  : std_logic_vector (31 downto 0) := x"00000000";
    TOP_VER     : std_logic_vector (31 downto 0) := x"00000000";
    TOP_SHA     : std_logic_vector (31 downto 0) := x"00000000";
    HOG_SHA     : std_logic_vector (31 downto 0) := x"00000000";
    HOG_VER     : std_logic_vector (31 downto 0) := x"00000000";
    REPO_SHA    : std_logic_vector (31 downto 0) := x"00000000";
    REPO_VER    : std_logic_vector (31 downto 0) := x"00000000"
    );
  port (

    -- 33MHz ADC clock
    clock_i_p : in std_logic;
    clock_i_n : in std_logic;

    -- Data pins from ADC
    adc_data_i : in std_logic_vector (13 downto 0);

    -- DRS IO
    drs_srout_i   : in  std_logic;                      -- Multiplexed Shift Register Outpu
    drs_addr_o    : out std_logic_vector (3 downto 0);  -- Address Bit Inputs
    drs_denable_o : out std_logic;                      -- Domino Enable Input. A low-to-high transition starts the Domino Wave. Set-ting this input low stops the Domino Wave.
    drs_dwrite_o  : out std_logic;                      -- Domino Write Input. Connects the Domino Wave Circuit to the Sampling Cells to enable sampling if high.
    drs_rsrload_o : out std_logic;                      -- Read Shift Register Load Input
    drs_srclk_o   : out std_logic;                      -- Multiplexed Shift Register Clock Input
    drs_srin_o    : out std_logic;                      -- Shared Shift Register Input
    drs_nreset_o  : out std_logic;                      --
    drs_plllock_i : in  std_logic;                      --
    drs_dtap_i    : in  std_logic;                      --

    mt_trigger_i_p : in std_logic;     -- trigger_i from rj45
    mt_trigger_i_n : in std_logic;     -- trigger_i from rj45

    ext_trigger_i : in std_logic;

    -- GFP io
    gfp_sclk : in std_logic;
    gfp_sdat : in std_logic;

    -- Zynq IO
    emio_scl          : inout std_logic;
    emio_sda          : inout std_logic;
    fixed_io_mio      : inout std_logic_vector (53 downto 0);
    fixed_io_ddr_vrn  : inout std_logic;
    fixed_io_ddr_vrp  : inout std_logic;
    fixed_io_ps_srstb : inout std_logic;
    fixed_io_ps_clk   : inout std_logic;
    fixed_io_ps_porb  : inout std_logic;
    ddr_cas_n         : inout std_logic;
    ddr_cke           : inout std_logic;
    ddr_ck_n          : inout std_logic;
    ddr_ck_p          : inout std_logic;
    ddr_cs_n          : inout std_logic;
    ddr_reset_n       : inout std_logic;
    ddr_odt           : inout std_logic;
    ddr_ras_n         : inout std_logic;
    ddr_we_n          : inout std_logic;
    ddr_ba            : inout std_logic_vector (2 downto 0);
    ddr_addr          : inout std_logic_vector (14 downto 0);
    ddr_dm            : inout std_logic_vector (3 downto 0);
    ddr_dq            : inout std_logic_vector (31 downto 0);
    ddr_dqs_n         : inout std_logic_vector (3 downto 0);
    ddr_dqs_p         : inout std_logic_vector (3 downto 0);

    loss_of_lock_i    : in std_logic;

    led : out std_logic_vector (3 downto 0)

    -- gpio_p : inout std_logic_vector (9 downto 0);
    -- gpio_n : inout std_logic_vector (9 downto 0)

    );
end top_readout_board;

architecture Behavioral of top_readout_board is

  signal clock              : std_logic;
  signal clock_i            : std_logic := '0';
  signal clk200             : std_logic := '0';
  signal clock_i_dly        : std_logic := '0';
  signal trg_clk_oversample : std_logic := '0';
  signal locked             : std_logic;

  signal clock_tap_delays : std_logic_vector (4 downto 0) := (others => '0');

  signal lock_of_lock : std_logic := '0';

  signal reset : std_logic;

  -- RAM Buffer occupancy
  signal ram_buff_a_occupancy : std_logic_vector(31 downto 0) := (others => '0');
  signal ram_buff_b_occupancy : std_logic_vector(31 downto 0) := (others => '0');
  signal dma_pointer          : std_logic_vector(31 downto 0);
  signal ram_a_occ_rst        : std_logic;
  signal ram_b_occ_rst        : std_logic;
  signal ram_toggle_request   : std_logic;

  signal drs_data         : std_logic_vector (13 downto 0);
  signal drs_rden         : std_logic := '0';
  signal drs_data_valid   : std_logic;
  signal drs_dwrite_sync  : std_logic;
  signal drs_dwrite_async : std_logic;
  signal drs_dwrite_mask  : std_logic := '1';

  -- Trigger Signals
  signal start_readout         : std_logic := '0';
  signal trigger               : std_logic := '0';

  signal adc_posneg            : std_logic;
  signal srout_posneg          : std_logic;
  signal srout_latency         : std_logic_vector(2 downto 0);

  signal ext_trigger_active_hi : std_logic := '0';

  signal mt_trigger_i           : std_logic              := '0';
  signal mt_trigger_data_xdeco  : std_logic              := '0';
  signal mt_trigger_data        : std_logic              := '0';
  signal mt_trigger_data_pol    : std_logic              := '0';
  signal mt_trigger_dav         : std_logic              := '0';
  signal mt_trigger_data_ff     : std_logic              := '0';
  signal mt_prbs_err            : std_logic              := '0';
  signal mt_prbs_rst            : std_logic              := '0';
  signal mt_inactive            : std_logic              := '0';
  signal mt_inactive_cnts       : integer range 0 to 63  := 0;
  signal mt_active_hi_cnts      : integer range 0 to 127 := 0;

  signal mt_fifo_wr_req     : std_logic                      := '0';
  signal mt_event_cnt_valid : std_logic                      := '0';
  signal mt_mask_valid      : std_logic                      := '0';
  signal mt_mask            : std_logic_vector (7 downto 0)  := (others => '0');
  signal mt_event_cnt       : std_logic_vector (31 downto 0);
  signal mt_event_cnt_prev  : std_logic_vector (31 downto 0) := (others => '0');
  signal mt_event_cnt_err   : std_logic;
  signal mt_cmd             : std_logic_vector(1 downto 0);
  signal mt_cmd_valid       : std_logic;
  signal mt_link_id         : std_logic_vector(5 downto 0);
  signal mt_link_id_valid   : std_logic;
  signal mt_crc             : std_logic_vector(7 downto 0);
  signal mt_crc_calc        : std_logic_vector(7 downto 0);
  signal mt_crc_valid       : std_logic;
  signal mt_crc_ok          : std_logic;
  signal mt_resync          : std_logic;

  signal trigger_enable      : std_logic := '0';
  signal ext_trigger_en      : std_logic := '0';
  signal force_trig          : std_logic := '0';
  signal mt_is_level_trigger : std_logic := '0';
  signal mt_level_trigger    : std_logic := '0';

  signal trigger_rate      : std_logic_vector (31 downto 0) := (others => '0');
  signal lost_trigger_rate : std_logic_vector (31 downto 0) := (others => '0');
  signal mt_trigger_rate   : std_logic_vector (31 downto 0) := (others => '0');

  signal trig_deadcnt    : integer range 0 to 15          := 0;
  signal trig_gen_rate   : std_logic_vector (31 downto 0) := (others => '0');
  signal trig_gen        : std_logic                      := '0';
  signal trig_gen_gated  : std_logic                      := '0';

  signal mt_trigger                  : std_logic := '0';
  signal mt_trigger_fast             : std_logic := '0';
  signal mt_fragment                 : std_logic := '0';
  signal cnt_reset                   : std_logic := '0';

  signal mt_trigger_mode             : std_logic := '1';
  signal mt_trigger_mode_last        : std_logic := '1';
  signal mt_trigger_mode_is_toggling : std_logic := '1';

  -- DAQ
  signal daq_busy            : std_logic := '0';
  signal daq_ready           : std_logic := '0';
  signal debug_packet_inject : std_logic;
  signal dma_idle            : std_logic := '0';

  signal sem_correction          : std_logic;
  signal sem_uncorrectable_error : std_logic;

  -------------------------------------------------------------------------------
  -- DRS configuration
  -------------------------------------------------------------------------------

  signal drs_diagnostic_mode : std_logic := '0';

  signal drs_srclk_en      : std_logic;
  signal drs_busy          : std_logic;
  signal drs_idle          : std_logic;
  signal drs_busy_latch    : std_logic;
  signal drs_roi_mode      : std_logic;
  signal drs_spike_removal : std_logic;
  signal drs_dmode         : std_logic;
  signal drs_reinit        : std_logic;
  signal drs_configure     : std_logic;
  signal drs_standby_mode  : std_logic;
  signal drs_start         : std_logic;
  signal drs_transp_mode   : std_logic;

  signal wait_vdd_clocks : std_logic_vector (15 downto 0);

  signal readout_mask                  : std_logic_vector (8 downto 0);
  signal readout_mask_axi              : std_logic_vector (8 downto 0) := (others => '0');
  signal readout_mask_or               : std_logic_vector (8 downto 0) := (others => '0');
  signal readout_mask_9th_channel_auto : std_logic;
  signal read_ch8                      : std_logic                     := '0';

  signal drs_config          : std_logic_vector (7 downto 0);
  signal chn_config          : std_logic_vector (7 downto 0);
  signal drs_stop_cell       : std_logic_vector (9 downto 0);
  signal dna                 : std_logic_vector (56 downto 0);
  signal board_id            : std_logic_vector (7 downto 0);
  signal adc_latency         : std_logic_vector (5 downto 0);
  signal sample_count_max    : std_logic_vector (9 downto 0);
  signal drs_ctl_start_timer : std_logic_vector (7 downto 0);

  signal drs_reset        : std_logic;
  signal daq_reset        : std_logic;

  signal soft_reset                        : std_logic;
  signal soft_reset_done                   : std_logic;
  signal soft_reset_drs, soft_reset_drs_en : std_logic;
  signal soft_reset_daq, soft_reset_daq_en : std_logic;
  signal soft_reset_dma, soft_reset_dma_en : std_logic;
  signal soft_reset_ptr, soft_reset_ptr_en : std_logic;
  signal soft_reset_buf, soft_reset_buf_en : std_logic;
  signal soft_reset_trg, soft_reset_trg_en : std_logic;
  signal soft_reset_wait_daq               : std_logic;
  signal soft_reset_wait_drs               : std_logic;
  signal soft_reset_wait_dma               : std_logic;

  signal timestamp : unsigned (47 downto 0) := (others => '0');

  signal dtap_cnt : std_logic_vector (15 downto 0);

  signal readout_complete : std_logic;

  signal spy_data  : std_logic_vector (15 downto 0) := (others => '0');
  signal spy_full  : std_logic                      := '0';
  signal spy_empty : std_logic                      := '0';
  signal spy_reset : std_logic                      := '0';
  signal spy_rd_en : std_logic                      := '0';
  signal spy_valid : std_logic                      := '0';

  -- ADC Readout
  signal drs_data_xfifo  : std_logic_vector (13 downto 0);
  signal drs_valid_xfifo : std_logic := '0';
  signal drs_fifo_empty  : std_logic := '0';

  signal fifo_data_out : std_logic_vector (15 downto 0);
  signal fifo_data_wen : std_logic;
  --fifo_fifo_busy : in std_logic;

  signal dma_packet_counter : std_logic_vector(31 downto 0);
  signal dma_control_reset  : std_logic := '0';
  signal dma_clear          : std_logic := '0';

  constant LOCK_POLARITY : std_logic := '0'; -- 0 == locked, 1 == unlocked
  signal lock_stable : std_logic := '0';
  signal lock_stable_counts : integer range 0 to 2**25-1 := 0;

  signal calibration : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpint     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpaux     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccoddr     : std_logic_vector(11 downto 0) := (others => '0');
  signal temp        : std_logic_vector(11 downto 0) := (others => '0');
  signal vccint      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccaux      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccbram     : std_logic_vector(11 downto 0) := (others => '0');

  signal drs_temp    : std_logic_vector (15 downto 0) := (others => '0');

  ------ Register signals begin (this section is generated by generate_registers.py -- do not edit)
  signal regs_read_arr        : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_write_arr       : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_addresses       : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_defaults        : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
  signal regs_read_pulse_arr  : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0) := (others => '0');
  signal regs_write_pulse_arr : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0) := (others => '0');
  signal regs_read_ready_arr  : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0) := (others => '1');
  signal regs_write_done_arr  : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0) := (others => '1');
  signal regs_writable_arr    : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0) := (others => '0');
    -- Connect counter signal declarations
  signal cnt_mt_prbs_err : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_mt_crc_err : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_sem_corrected : std_logic_vector (15 downto 0) := (others => '0');
  signal cnt_sem_uncorrectable : std_logic_vector (3 downto 0) := (others => '0');
  signal cnt_readouts : std_logic_vector (31 downto 0) := (others => '0');
  signal cnt_lost_events : std_logic_vector (15 downto 0) := (others => '0');
  signal event_counter : std_logic_vector (31 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------

  signal daq_event_cnt         : std_logic_vector(31 downto 0);
  signal daq_timestamp         : std_logic_vector(47 downto 0);
  signal daq_mask              : std_logic_vector(8 downto 0);
  signal daq_drs_busy          : std_logic;
  signal daq_event_ack         : std_logic := '0';
  signal daq_trigger           : std_logic := '0';
  signal daq_fragment          : std_logic := '0';
  signal daq_fragment_en       : std_logic := '0';
  signal daq_acknowledge       : std_logic := '0';

  signal xfifo_fragment  : std_logic_vector (0 downto 0);
  signal xfifo_trigger   : std_logic_vector (0 downto 0);
  signal xfifo_busy      : std_logic_vector (0 downto 0);
  signal xfifo_timestamp : std_logic_vector (timestamp'range);
  signal xfifo_mask      : std_logic_vector (readout_mask'range);
  signal xfifo_event_cnt : std_logic_vector (mt_event_cnt'range);

  signal event_queue_valid   : std_logic := '0';
  signal event_queue_wr_en   : std_logic := '0';
  signal event_queue_request : std_logic := '0';
  signal event_queue_rd_en   : std_logic := '0';
  signal event_queue_empty   : std_logic := '0';

  signal event_queue_din, event_queue_dout :
    std_logic_vector (
      xfifo_fragment'length +
      xfifo_busy'length +
      xfifo_event_cnt'length  +
      xfifo_mask'length  +
      xfifo_timestamp'length - 1 downto 0) := (others => '0');

  --IPbus
  signal ipb_reset    : std_logic;
  signal ipb_clk      : std_logic;
  signal ipb_miso_arr : ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
  signal ipb_mosi_arr : ipb_wbus_array(IPB_SLAVES - 1 downto 0);

  signal cylon      : std_logic_vector (3 downto 0) := (others => '0');
  signal cylon_mode : std_logic := '0';

begin

  -------------------------------------------------------------------------------
  -- MMCM / PLL
  -------------------------------------------------------------------------------

  ibufgds0: IBUFGDS
    port map(
      i  => clock_i_p,
      ib => clock_i_n,
      o  => clock_i
      );

  delayctrl_inst : IDELAYCTRL
    port map (
      RDY    => open,
      REFCLK => clk200,
      RST    => reset
      );

  idelay_clk : entity work.idelay
    generic map (
      PATTERN => "clock"
      )
    port map (
      clock => trg_clk_oversample,
      taps  => clock_tap_delays,
      din   => clock_i,
      dout  => clock_i_dly
      );

  clock_wizard_inst : clock_wizard
    port map (
      drs_clk   => clock,
      trg_clk   => open,
      trg_clk8x => trg_clk_oversample,
      daq_clk   => open,
      locked    => locked,
      clk_in1   => clock_i_dly
      );

  clk200 <= trg_clk_oversample;

  --------------------------------------------------------------------------------
  -- Reset
  --------------------------------------------------------------------------------

  process (clock, locked) is
  begin
    if (locked = '0') then
      reset <= '1';
    elsif (rising_edge(clock)) then
      reset <= '0';
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- LED Control
  --------------------------------------------------------------------------------

  cylon1_inst : cylon1
    port map (
      clock => clock,
      rate  => "00",
      q     => cylon
      );

  led <= not cylon when cylon_mode='1' else x"F";

  --------------------------------------------------------------------------------
  -- MT Trigger Input
  --------------------------------------------------------------------------------

  ibuftrigger : IBUFDS
    generic map (                       --
      DIFF_TERM    => true,             -- Differential Termination
      IBUF_LOW_PWR => true              -- Low power="TRUE", Highest performance="FALSE"
      )
    port map (
      O  => mt_trigger_i,              -- Buffer output
      I  => mt_trigger_i_p,            -- Diff_p buffer input (connect directly to top-level port)
      IB => mt_trigger_i_n             -- Diff_n buffer input (connect directly to top-level port)
      );

  mt_level_trigger <= mt_trigger_i when mt_is_level_trigger = '1' else '0';

  --------------------------------------------------------------------------------
  -- MT Manchester Decoder
  --------------------------------------------------------------------------------

  manchester_decoder_inst : entity work.manchester_decoder
    port map (
      clk  => trg_clk_oversample,
      din  => mt_trigger_i and not mt_is_level_trigger,
      dout => mt_trigger_data_xdeco,
      dav  => mt_trigger_dav
      );

  -- automatic polarity inversion of the mt trigger data for long seqs of
  -- constant data... link should be active low, so listen for sequences of
  -- active high and deactivate the link if we detect it
  mt_trigger_data <= mt_trigger_data_pol xor mt_trigger_data_xdeco;

  --------------------------------------------------------------------------------
  -- MT PRBS Checker
  --------------------------------------------------------------------------------

  process (trg_clk_oversample) is
  begin
    if (rising_edge(trg_clk_oversample)) then

      mt_trigger_data_ff <= mt_trigger_data_xdeco;

      if (mt_trigger_data_xdeco /= mt_trigger_data_ff) then
        mt_inactive_cnts <= 0;
        mt_inactive      <= '0';
      elsif (mt_inactive_cnts = 63) then
        mt_inactive <= '1';
      elsif (mt_inactive_cnts < 63) then
        mt_inactive_cnts <= mt_inactive_cnts + 1;
      end if;
    end if;
  end process;

  process (trg_clk_oversample) is
  begin
    if (rising_edge(trg_clk_oversample)) then
      if (mt_trigger_dav = '1') then
        if (mt_trigger_data = '0') then
          mt_active_hi_cnts <= 0;
        elsif (mt_active_hi_cnts < 127) then
          mt_active_hi_cnts <= mt_active_hi_cnts + 1;
        elsif (mt_active_hi_cnts = 127) then
          mt_active_hi_cnts   <= 0;
          mt_trigger_data_pol <= not mt_trigger_data_pol;
        end if;
      end if;
    end if;
  end process;

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
      clk         => trg_clk_oversample,
      data_in(0)  => mt_trigger_data,
      en          => mt_trigger_dav,
      data_out(0) => mt_prbs_err
      );

  gen_debug : if (DEBUG) generate

    component ila_s2mm is
      port (
        clk     : in std_logic;
        probe0  : in std_logic;
        probe1  : in std_logic;
        probe2  : in std_logic_vector(71 downto 0);
        probe3  : in std_logic_vector(31 downto 0);
        probe4  : in std_logic_vector(3 downto 0);
        probe5  : in std_logic;
        probe6  : in std_logic;
        probe7  : in std_logic;
        probe8  : in std_logic_vector(31 downto 0);
        probe9  : in std_logic;
        probe10 : in std_logic_vector(31 downto 0);
        probe11 : in std_logic;
        probe12 : in std_logic;
        probe13 : in std_logic;
        probe14 : in std_logic;
        probe15 : in std_logic_vector(7 downto 0);
        probe16 : in std_logic;
        probe17 : in std_logic;
        probe18 : in std_logic_vector(7 downto 0);
        probe19 : in std_logic;
        probe20 : in std_logic;
        probe21 : in std_logic_vector(15 downto 0);
        probe22 : in std_logic_vector(31 downto 0);
        probe23 : in std_logic;
        probe24 : in std_logic_vector(33 downto 0);
        probe25 : in std_logic_vector(7 downto 0);
        probe26 : in std_logic_vector(5 downto 0)
        );
    end component;

  begin
    ila_s2mm_inst : ila_s2mm
      port map(
        clk                   => clock,
        probe0                => mt_trigger_data,
        probe1                => daq_acknowledge,
        probe2(31 downto 0)   => ipb_mosi_arr(0).ipb_wdata(31 downto 0),
        probe2(63 downto 32)  => ipb_miso_arr(0).ipb_rdata(31 downto 0),
        probe2(64)            => ipb_miso_arr(0).ipb_ack, 
        probe2(65)            => ipb_miso_arr(0).ipb_err, 
        probe2(66)            => ipb_mosi_arr(0).ipb_strobe, 
        probe2(67)            => ipb_mosi_arr(0).ipb_write, 
        probe2(68)            => xfifo_trigger(0),
        probe2(69)            => mt_trigger_mode, 
        probe2(70)            => trigger_enable,
        probe2(71)            => soft_reset_trg,
        probe3(15 downto 0)   => fifo_data_out,
        probe3(16)            => drs_dwrite_async,
        probe3(17)            => daq_ready,
        probe3(18)            => ext_trigger_i,
        probe3(27 downto 19)  => readout_mask,
        probe3(28)            => mt_mask_valid,
        probe3(29)            => daq_drs_busy,
        probe3(30)            => mt_event_cnt_err,
        probe3(31)            => mt_resync,
        probe4                => (others => '0'),
        probe5                => mt_prbs_err,
        probe6                => event_queue_valid,
        probe7                => loss_of_lock_i,
        probe8                => mt_event_cnt,
        probe9                => mt_trigger_dav,
        probe10               => daq_event_cnt,
        probe11               => mt_trigger_dav,
        probe12               => drs_dwrite_o,
        probe13               => mt_event_cnt_valid,
        probe14               => daq_trigger,
        probe15(1 downto 0)   => mt_cmd,
        probe15(2)            => mt_cmd_valid,
        probe15(3)            => mt_crc_valid,
        probe15(4)            => mt_crc_ok,
        probe15(5)            => daq_fragment,
        probe15(6)            => mt_fragment,
        probe15(7)            => start_readout,
        probe16               => daq_busy,
        probe17               => drs_busy,
        probe18               => (others => '0'),
        probe19               => trigger,
        probe20               => mt_trigger,
        probe21(8 downto 0)   => daq_mask,
        probe21(9)            => drs_reinit,
        probe21(10)           => drs_start,
        probe21(11)           => drs_idle,
        probe21(12)           => event_queue_rd_en,
        probe21(13)           => event_queue_request,
        probe21(14)           => event_queue_empty,
        probe21(15)           => daq_ready,
        probe22(13 downto 0)  => drs_data,
        probe22(14)           => drs_data_valid,
        probe22(28 downto 15) => drs_data_xfifo,
        probe22(29)           => drs_valid_xfifo,
        probe22(30)           => drs_rden,
        probe22(31)           => mt_trigger_data_xdeco,
        probe23               => fifo_data_wen,
        probe24(7 downto 0)   => mt_crc_calc,
        probe24(8)            => force_trig,
        probe24(16 downto 9)  => mt_mask, 
        probe24(33 downto 17) => (others => '0'),
        probe25               => mt_crc,
        probe26               => (others => '0')
        );
  end generate;

  --------------------------------------------------------------------------------
  -- MT Receiver
  --------------------------------------------------------------------------------

  mt_rx_inst : entity work.mt_rx
    generic map (
      EVENTCNTB => mt_event_cnt'length,
      MASKB     => mt_mask'length,
      CMDB      => mt_cmd'length
      )
    port map (
      clock  => trg_clk_oversample,
      outclk => clock,
      reset  => reset,

      -- provide a 200MHz copy of the trigger signal for a fast route to dwrite
      -- and a 33MHz copy for the rest of the logic
      trg_fast_o    => mt_trigger_fast,
      trg_o         => mt_trigger,
      fragment_o    => mt_fragment,
      fragment_en_i => daq_fragment_en,

      serial_i    => mt_trigger_data,
      enable_i    => mt_trigger_mode and mt_trigger_dav,
      cmd_o       => mt_cmd,
      cmd_valid_o => mt_cmd_valid,

      link_id_o       => mt_link_id,
      link_id_valid_o => mt_link_id_valid,

      crc_ok_o    => mt_crc_ok,
      crc_o       => mt_crc,
      crc_calc_o  => mt_crc_calc,
      crc_valid_o => mt_crc_valid,

      event_cnt_o       => mt_event_cnt,
      event_cnt_valid_o => mt_event_cnt_valid,

      mask_o       => mt_mask,
      mask_valid_o => mt_mask_valid,

      fifo_wr_o    => mt_fifo_wr_req
      );

  process (clock) is
  begin
    if (rising_edge(clock)) then
      mt_event_cnt_prev <= mt_event_cnt;
      mt_event_cnt_err  <= '0';
      if (mt_event_cnt_valid = '1') then
        if (unsigned(mt_event_cnt_prev)+0 /= unsigned(mt_event_cnt) and
            unsigned(mt_event_cnt_prev)+1 /= unsigned(mt_event_cnt) and
            unsigned(mt_event_cnt_prev)+2 /= unsigned(mt_event_cnt)) then
          mt_event_cnt_err <= '1';
        end if;
      end if;
    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      mt_resync <= '0';

      if (mt_cmd_valid='1') then
        case mt_cmd is
          when "11" =>
            mt_resync <= '1';
          when others =>
        end case;

      end if;
    end if;
  end process;


  --------------------------------------------------------------------------------
  -- Event Queue
  --------------------------------------------------------------------------------

  event_queue_din <= mt_fragment & mt_event_cnt & readout_mask & drs_busy_latch & std_logic_vector(timestamp);

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (event_queue_valid = '1') then 
        xfifo_timestamp <= event_queue_dout(xfifo_timestamp'length-1 downto 0);
        xfifo_busy      <= event_queue_dout(xfifo_timestamp'length downto xfifo_timestamp'length);
        xfifo_mask      <= event_queue_dout(xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length - 1 downto xfifo_busy'length + xfifo_timestamp'length);
        xfifo_event_cnt <= event_queue_dout(xfifo_event_cnt'length + xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length - 1 downto xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length);
        xfifo_fragment  <= event_queue_dout(xfifo_event_cnt'length + xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length downto xfifo_event_cnt'length + xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length);
        xfifo_trigger   <= not event_queue_dout(xfifo_event_cnt'length + xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length downto xfifo_event_cnt'length + xfifo_mask'length + xfifo_timestamp'length + xfifo_busy'length);
      else 
        xfifo_timestamp <= (others => '0');
        xfifo_busy      <= (others => '0');
        xfifo_mask      <= (others => '0');
        xfifo_event_cnt <= (others => '0');
        xfifo_fragment  <= (others => '0');
        xfifo_trigger   <= (others => '0');
      end if; 
    end if;
  end process;

  -- save a copy of whether the drs was busy when the trigger was received,
  -- push this into the FIFO when the rest of the metadata is received
  -- i.e. the event count... this is needed since the start signal comes early,
  -- as soon as the MT packet shows up, but the metadata comes later
  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (start_readout = '1') then
        drs_busy_latch <= drs_busy;
      end if;
    end if;
  end process;

  event_queue_wr_en <= trigger_enable and mt_fifo_wr_req and not soft_reset_trg;

  event_fifo_inst : entity work.fifo_sync
    generic map (
      DEPTH     => 128,
      WR_WIDTH  => event_queue_din'length,
      RD_WIDTH  => event_queue_din'length
      )
    port map (
      rst    => reset or soft_reset_buf,
      clk    => clock,
      wr_en  => event_queue_wr_en,
      rd_en  => event_queue_rd_en,
      din    => event_queue_din,
      dout   => event_queue_dout,
      valid  => event_queue_valid,
      full   => open,
      empty  => event_queue_empty
      );

  -- when the daq is ready, read one and only one event from the event queue
  process (clock) is
  begin
    if (rising_edge(clock)) then

      event_queue_rd_en <= '0';

      -- if the daq is ready, and there are events in the queue, and a read has
      -- not already been requested, then request one
      if (daq_ready = '1' and event_queue_empty = '0' and event_queue_request = '0') then
        event_queue_rd_en   <= '1';
        event_queue_request <= '1';
      -- deassert the request once an ack has been received
      elsif (daq_acknowledge = '1') then
        event_queue_request <= '0';
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Trigger output
  --------------------------------------------------------------------------------

  drs_dwrite_o <= drs_dwrite_mask and drs_dwrite_sync and drs_dwrite_async;

  trigger_mux_inst : entity work.trigger_mux
    generic map (TRIGGER_OS_MAX => 3)
    port map (
      clock => clock,

      enable => trigger_enable and not soft_reset_trg,

      ext_trigger_i         => ext_trigger_i or mt_level_trigger,
      ext_trigger_en        => ext_trigger_en,
      ext_trigger_active_hi => ext_trigger_active_hi,

      force_trig => force_trig or (trig_gen_gated and not drs_busy),

      master_trigger => mt_trigger_mode and (mt_trigger or mt_trigger_fast),

      trigger_o => trigger,
      dwrite_o  => drs_dwrite_async
      );

  --------------------------------------------------------------------------------
  -- DTAP Monitoring
  --------------------------------------------------------------------------------

  dtap_inst : entity work.dtap
    generic map (
      WIDTH => dtap_cnt'length,
      MHZ   => CLK_FREQUENCY,
      DIV   => 100
      )
    port map (
      clock      => clock,
      drs_dtap_i => drs_dtap_i,
      dtap_cnt_o => dtap_cnt
      );

  -------------------------------------------------------------------------------
  -- SRCLK ODDR
  -------------------------------------------------------------------------------

  -- put srclk on an oddr
  drs_srclk_oddr : ODDR
    generic map (                       --
      DDR_CLK_EDGE => "OPPOSITE_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE"
      INIT         => '0',              -- Initial value of Q: 1'b0 or 1'b1
      SRTYPE       => "SYNC"            -- Set/Reset type: "SYNC" or "ASYNC"
      )
    port map (
      Q  => drs_srclk_o,                -- 1-bit DDR output
      C  => clock,                      -- 1-bit clock input
      CE => '1',                        -- 1-bit clock enable input
      D1 => '1',                        -- 1-bit data input (positive edge)
      D2 => '0',                        -- 1-bit data input (negative edge)
      R  => not drs_srclk_en,           -- 1-bit reset
      S  => '0'                         -- 1-bit set
      );

  -------------------------------------------------------------------------------
  -- Timestamp
  -------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or mt_resync = '1') then
        timestamp <= (others => '0');
      else
        timestamp <= timestamp + 1;
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- DRS Control Module
  -------------------------------------------------------------------------------

  -- take the readout mask from either the trigger or axi control
  readout_mask_or <= ("0" & mt_mask) when mt_trigger_mode='1' else readout_mask_axi;
  read_ch8        <= readout_mask_9th_channel_auto and or_reduce(readout_mask_or (7 downto 0));
  readout_mask    <= readout_mask_or or (read_ch8 & x"00");

  drs_config(0) <= drs_dmode;
  drs_config(1) <= '1';                 -- pllen
  drs_config(2) <= '0';                 -- wrsloop

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (mt_trigger_mode='0') then
        start_readout   <= trigger;
        drs_dwrite_mask <= '1';
      else
        start_readout <= mt_mask_valid;

        -- when we get a trigger, dwrite goes low, keep it low until we get the
        -- mask and the drs module itself takes over the dwrite
        if (trigger = '1') then
          drs_dwrite_mask <= '0';
        elsif (drs_dwrite_sync = '0') then
          drs_dwrite_mask <= '1';
        end if;

      end if;
    end if;
  end process;

  drs_inst : drs
    port map (
      clock     => clock,
      reset     => reset or drs_reset or soft_reset_drs,
      trigger_i => start_readout and not soft_reset_trg,

      posneg_i        => adc_posneg,
      srout_posneg_i  => srout_posneg,
      srout_latency_i => srout_latency,

      adc_data_i => adc_data_i,

      diagnostic_mode => drs_diagnostic_mode,

      drs_ctl_roi_mode         => drs_roi_mode,  -- 1 bit roi input
      drs_ctl_dmode            => drs_dmode, -- 1 bit dmode input
      drs_ctl_config           => drs_config(7 downto 0),
      drs_ctl_standby_mode     => drs_standby_mode,
      drs_ctl_transp_mode      => drs_transp_mode,
      drs_ctl_start            => drs_start,
      drs_ctl_start_timer      => drs_ctl_start_timer,
      drs_ctl_adc_latency      => adc_latency,
      drs_ctl_spike_removal    => drs_spike_removal,
      drs_ctl_sample_count_max => sample_count_max,
      drs_ctl_reinit           => drs_reinit,
      drs_ctl_configure_drs    => drs_configure,
      drs_ctl_chn_config       => chn_config(7 downto 0),
      drs_ctl_readout_mask_i   => readout_mask(8 downto 0),
      drs_ctl_wait_vdd_clocks  => wait_vdd_clocks,

      drs_srout_i => drs_srout_i,

      drs_addr_o      => drs_addr_o(3 downto 0),
      drs_nreset_o    => drs_nreset_o,
      drs_denable_o   => drs_denable_o,
      drs_dwrite_o    => drs_dwrite_sync,
      drs_rsrload_o   => drs_rsrload_o,
      drs_srclk_en_o  => drs_srclk_en,
      drs_srin_o      => drs_srin_o,
      drs_stop_cell_o => drs_stop_cell,

      fifo_wdata_o => drs_data,
      fifo_wen_o   => drs_data_valid,

      readout_complete => open,

      busy_o => drs_busy,
      idle_o => drs_idle

      );

  --------------------------------------------------------------------------------
  -- Soft Reset
  --------------------------------------------------------------------------------

  soft_reset_inst : entity work.soft_reset
    port map (
      clock               => clock,
      reset               => reset,
      drs_busy            => drs_busy,
      drs_idle            => drs_idle,
      daq_busy            => daq_busy,
      dma_idle            => dma_idle,
      soft_reset_i        => soft_reset,
      soft_reset_done     => soft_reset_done,
      soft_reset_drs      => soft_reset_drs,
      soft_reset_daq      => soft_reset_daq,
      soft_reset_dma      => soft_reset_dma,
      soft_reset_ptr      => soft_reset_ptr,
      soft_reset_buf      => soft_reset_buf,
      soft_reset_trg      => soft_reset_trg,
      soft_reset_drs_en   => soft_reset_drs_en,
      soft_reset_daq_en   => soft_reset_daq_en,
      soft_reset_dma_en   => soft_reset_dma_en,
      soft_reset_ptr_en   => soft_reset_ptr_en,
      soft_reset_buf_en   => soft_reset_buf_en,
      soft_reset_trg_en   => soft_reset_trg_en,
      soft_reset_wait_daq => soft_reset_wait_daq,
      soft_reset_wait_drs => soft_reset_wait_drs,
      soft_reset_wait_dma => soft_reset_wait_dma);

  -------------------------------------------------------------------------------
  -- Clear buffers when switching trigger modes
  -------------------------------------------------------------------------------

  process (clock) is
  begin
    if (rising_edge(clock)) then

      mt_trigger_mode_last <= mt_trigger_mode;

      if (mt_trigger_mode /= mt_trigger_mode_last) then
        mt_trigger_mode_is_toggling <= '1';
      else
        mt_trigger_mode_is_toggling <= '0';
      end if;

    end if;
  end process;

  -------------------------------------------------------------------------------
  -- DAQ
  -------------------------------------------------------------------------------

  daq_fifo_inst : entity work.fifo_sync
    generic map (
      DEPTH     => 1024,
      WR_WIDTH  => 14,
      RD_WIDTH  => 14
      )
    port map (
      rst    => reset or soft_reset_buf,
      clk    => clock,                  -- daq_clock
      wr_en  => drs_data_valid,
      rd_en  => drs_rden,
      din    => drs_data,
      dout   => drs_data_xfifo,
      valid  => drs_valid_xfifo,
      full   => open,
      empty  => drs_fifo_empty
      );

  daq_event_cnt <= xfifo_event_cnt   when mt_trigger_mode = '1' else event_counter;
  daq_timestamp <= xfifo_timestamp   when mt_trigger_mode = '1' else std_logic_vector(timestamp);
  daq_mask      <= xfifo_mask        when mt_trigger_mode = '1' else readout_mask;
  daq_drs_busy  <= xfifo_busy(0)     when mt_trigger_mode = '1' else drs_busy;
  daq_trigger   <= xfifo_trigger(0)  when mt_trigger_mode = '1' else trigger;
  daq_fragment  <= xfifo_fragment(0) when mt_trigger_mode = '1' else '0';

  daq_inst : entity work.daq
    port map (
      clock                 => clock,
      reset                 => reset or daq_reset or soft_reset_daq,
      debug_packet_inject_i => debug_packet_inject,
      temperature_i         => temp,
      loss_of_lock_i        => loss_of_lock_i,
      lock_stable           => lock_stable,
      stop_cell_i           => drs_stop_cell,

      event_cnt_i => daq_event_cnt,
      timestamp_i => daq_timestamp,
      mask_i      => daq_mask,
      drs_busy_i  => daq_drs_busy,
      trigger_i   => daq_trigger and not soft_reset_trg,
      fragment_i  => daq_fragment_en and daq_fragment,

      ack_o  => daq_acknowledge,

      board_id    => board_id,
      sync_err_i  => '0',
      dna_i       => "0000000" & dna,
      hash_i      => GLOBAL_SHA,
      roi_size_i  => sample_count_max,
      dtap_i      => dtap_cnt,
      drs_temp_i  => drs_temp,

      drs_data_i  => drs_data_xfifo,
      drs_valid_i => drs_valid_xfifo,
      drs_rden_o  => drs_rden,

      data_o      => fifo_data_out,
      valid_o     => fifo_data_wen,
      busy_o      => daq_busy,
      ready_o     => daq_ready,
      done_o      => readout_complete
      );

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (loss_of_lock_i = LOCK_POLARITY) then
        lock_stable_counts <= 33000000; -- 1 second
      elsif (lock_stable_counts > 0) then
        lock_stable_counts <= lock_stable_counts-1;
      end if;

      if (lock_stable_counts = 0) then
        lock_stable <= '1';
      else
        lock_stable <= '0';
      end if;

    end if;
  end process;


  -------------------------------------------------------------------------------
  -- Spybuffer
  -------------------------------------------------------------------------------

  -- fifo to read data through the "spybuffer"
  spy_fifo_inst : entity work.fifo_async
    generic map (
      DEPTH    => 16384,
      WR_WIDTH => 16,
      RD_WIDTH => 16
      )
    port map (
      rst    => reset or spy_reset or soft_reset_buf,
      wr_clk => clock,                  -- daq_clock
      rd_clk => clock,
      wr_en  => fifo_data_wen,
      rd_en  => spy_rd_en,
      din    => fifo_data_out,
      dout   => spy_data,
      valid  => spy_valid,
      full   => spy_full,
      empty  => spy_empty
      );

  -------------------------------------------------------------------------------
  -- Soft Error Mitigation
  -------------------------------------------------------------------------------

  sem_wrapper : entity work.sem_wrapper
    port map (
      clk_i            => clock,
      correction_o     => sem_correction,
      classification_o => open,
      uncorrectable_o  => sem_uncorrectable_error,
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

  -------------------------------------------------------------------------------
  -- Device DNA
  -------------------------------------------------------------------------------

  device_dna_inst : device_dna
    port map(
      clock => clock,
      reset => reset,
      dna   => dna
      );

  --------------------------------------------------------------------------------
  -- Rate Counter
  --------------------------------------------------------------------------------

  rate_counter_trigger : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => std_logic_vector(to_unsigned(CLK_FREQUENCY,32)),
      g_COUNTER_WIDTH => 32
      )
    port map (
      clk_i   => clock,
      reset_i => reset,
      en_i    => trigger,
      rate_o  => trigger_rate
      );

  rate_counter_lost_trigger : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => std_logic_vector(to_unsigned(CLK_FREQUENCY,32)),
      g_COUNTER_WIDTH => 32
      )
    port map (
      clk_i   => clock,
      reset_i => reset,
      en_i    => trigger and drs_busy,
      rate_o  => lost_trigger_rate
      );

  rate_counter_mt_trigger : entity work.rate_counter
    generic map (
      g_CLK_FREQUENCY => std_logic_vector(to_unsigned(CLK_FREQUENCY,32)),
      g_COUNTER_WIDTH => 32
      )
    port map (
      clk_i   => clock,
      reset_i => reset,
      en_i    => event_queue_wr_en,
      rate_o  => mt_trigger_rate
      );

  --------------------------------------------------------------------------------
  -- Trigger generator
  --------------------------------------------------------------------------------

  -- enforce a few clock cycles minimum separation;
  -- give time for the drs to go busy
  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (trig_deadcnt = 0 and trig_gen = '1') then
        trig_deadcnt   <= 15;
        trig_gen_gated <= '1';
      elsif (trig_deadcnt > 0) then
        trig_deadcnt   <= trig_deadcnt - 1;
        trig_gen_gated <= '0';
      end if;
    end if;
  end process;


  trig_gen_inst : entity work.trig_gen
    port map (
      sys_clk    => clock,
      sys_rst    => reset,
      sys_bx_stb => '1',
      rate       => trig_gen_rate,
      trig       => trig_gen
      );

  -------------------------------------------------------------------------------
  -- Interface to processing system for DMA, AXI, etc...
  -------------------------------------------------------------------------------

  ps_interface_inst : entity work.ps_interface
    port map (

      fixed_io_mio      => fixed_io_mio,
      fixed_io_ddr_vrn  => fixed_io_ddr_vrn,
      fixed_io_ddr_vrp  => fixed_io_ddr_vrp,
      fixed_io_ps_srstb => fixed_io_ps_srstb,
      fixed_io_ps_clk   => fixed_io_ps_clk,
      fixed_io_ps_porb  => fixed_io_ps_porb,

      ddr_cas_n   => ddr_cas_n,
      ddr_cke     => ddr_cke,
      ddr_ck_n    => ddr_ck_n,
      ddr_ck_p    => ddr_ck_p,
      ddr_cs_n    => ddr_cs_n,
      ddr_reset_n => ddr_reset_n,
      ddr_odt     => ddr_odt,
      ddr_ras_n   => ddr_ras_n,
      ddr_we_n    => ddr_we_n,
      ddr_ba      => ddr_ba,
      ddr_addr    => ddr_addr,
      ddr_dm      => ddr_dm,
      ddr_dq      => ddr_dq,
      ddr_dqs_n   => ddr_dqs_n,
      ddr_dqs_p   => ddr_dqs_p,

      emio_scl    => emio_scl,
      emio_sda    => emio_sda,

      fifo_data_in  => fifo_data_out,
      fifo_clock_in => clock,           -- TODO: separate daq clock
      fifo_data_wen => fifo_data_wen,

      packet_counter      => dma_packet_counter,
      dma_control_reset_i => dma_control_reset or soft_reset_dma,
      dma_clear           => dma_clear,

      clk33          => clock,
      pl_mmcm_locked => locked,

      ipb_reset    => ipb_reset,
      ipb_clk      => ipb_clk,
      ipb_miso_arr => ipb_miso_arr,
      ipb_mosi_arr => ipb_mosi_arr,

      -- DMA
      dma_reset_i => reset,
      daq_busy_in => daq_busy,
      dma_idle_o  => dma_idle,

      -- RAM occupancy monitoring
      ram_a_occ_rst_i        => ram_a_occ_rst or soft_reset_ptr,
      ram_b_occ_rst_i        => ram_b_occ_rst or soft_reset_ptr,
      ram_toggle_request_i   => ram_toggle_request,
      ram_buff_a_occupancy_o => ram_buff_a_occupancy,
      ram_buff_b_occupancy_o => ram_buff_b_occupancy,
      dma_pointer_o          => dma_pointer

      );

  -------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------
  -- BEWARE: AUTO GENERATED CODE LIES BELOW
  -------------------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------

  --===============================================================================================
  -- (this section is generated by tools/generate_registers.py -- do not edit)
  --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
  ipbus_slave_inst : entity work.ipbus_slave_tmr
      generic map(
         g_ENABLE_TMR           => EN_TMR_IPB_SLAVE_DRS,
         g_NUM_REGS             => REG_DRS_NUM_REGS,
         g_ADDR_HIGH_BIT        => REG_DRS_ADDRESS_MSB,
         g_ADDR_LOW_BIT         => REG_DRS_ADDRESS_LSB,
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
  regs_addresses(0)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"00";
  regs_addresses(1)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"01";
  regs_addresses(2)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"02";
  regs_addresses(3)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"03";
  regs_addresses(4)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"04";
  regs_addresses(5)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"10";
  regs_addresses(6)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"11";
  regs_addresses(7)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"12";
  regs_addresses(8)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"13";
  regs_addresses(9)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"14";
  regs_addresses(10)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"15";
  regs_addresses(11)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"16";
  regs_addresses(12)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"17";
  regs_addresses(13)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"18";
  regs_addresses(14)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"19";
  regs_addresses(15)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1a";
  regs_addresses(16)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1b";
  regs_addresses(17)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1c";
  regs_addresses(18)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1d";
  regs_addresses(19)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"20";
  regs_addresses(20)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"21";
  regs_addresses(21)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"24";
  regs_addresses(22)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"25";
  regs_addresses(23)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"26";
  regs_addresses(24)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"27";
  regs_addresses(25)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"28";
  regs_addresses(26)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"29";
  regs_addresses(27)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"2a";
  regs_addresses(28)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"2b";
  regs_addresses(29)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"30";
  regs_addresses(30)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"31";
  regs_addresses(31)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"40";
  regs_addresses(32)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"41";
  regs_addresses(33)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"43";
  regs_addresses(34)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"44";
  regs_addresses(35)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"45";
  regs_addresses(36)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"46";
  regs_addresses(37)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"47";
  regs_addresses(38)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"48";
  regs_addresses(39)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"49";
  regs_addresses(40)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"50";
  regs_addresses(41)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"51";
  regs_addresses(42)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"52";
  regs_addresses(43)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"53";
  regs_addresses(44)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"54";
  regs_addresses(45)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"55";
  regs_addresses(46)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"56";
  regs_addresses(47)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"57";
  regs_addresses(48)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"58";
  regs_addresses(49)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"59";
  regs_addresses(50)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"60";
  regs_addresses(51)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"61";
  regs_addresses(52)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"62";
  regs_addresses(53)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"63";
  regs_addresses(54)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"64";
  regs_addresses(55)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"65";
  regs_addresses(56)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"66";
  regs_addresses(57)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"67";
  regs_addresses(58)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"70";
  regs_addresses(59)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"71";
  regs_addresses(60)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"72";
  regs_addresses(61)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"00";
  regs_addresses(62)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"01";
  regs_addresses(63)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"02";
  regs_addresses(64)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"03";
  regs_addresses(65)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"04";
  regs_addresses(66)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"05";

  -- Connect read signals
  regs_read_arr(0)(REG_CHIP_DMODE_BIT) <= drs_dmode;
  regs_read_arr(0)(REG_CHIP_STANDBY_MODE_BIT) <= drs_standby_mode;
  regs_read_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= drs_transp_mode;
  regs_read_arr(0)(REG_CHIP_DRS_PLL_LOCK_BIT) <= drs_plllock_i;
  regs_read_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= chn_config;
  regs_read_arr(1)(REG_CHIP_DTAP_FREQ_MSB downto REG_CHIP_DTAP_FREQ_LSB) <= dtap_cnt;
  regs_read_arr(2)(REG_CHIP_CLK_IDELAY_MSB downto REG_CHIP_CLK_IDELAY_LSB) <= clock_tap_delays;
  regs_read_arr(3)(REG_CHIP_CYLON_MODE_BIT) <= cylon_mode;
  regs_read_arr(3)(REG_CHIP_START_TIMER_MSB downto REG_CHIP_START_TIMER_LSB) <= drs_ctl_start_timer;
  regs_read_arr(4)(REG_CHIP_LOSS_OF_LOCK_BIT) <= loss_of_lock_i;
  regs_read_arr(4)(REG_CHIP_LOSS_OF_LOCK_STABLE_BIT) <= lock_stable;
  regs_read_arr(5)(REG_READOUT_ROI_MODE_BIT) <= drs_roi_mode;
  regs_read_arr(5)(REG_READOUT_BUSY_BIT) <= drs_busy;
  regs_read_arr(5)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= adc_latency;
  regs_read_arr(5)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= sample_count_max;
  regs_read_arr(5)(REG_READOUT_EN_SPIKE_REMOVAL_BIT) <= drs_spike_removal;
  regs_read_arr(6)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= readout_mask_axi;
  regs_read_arr(6)(REG_READOUT_AUTO_9TH_CHANNEL_BIT) <= readout_mask_9th_channel_auto;
  regs_read_arr(13)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB) <= wait_vdd_clocks;
  regs_read_arr(14)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT) <= drs_diagnostic_mode;
  regs_read_arr(15)(REG_READOUT_POSNEG_BIT) <= adc_posneg;
  regs_read_arr(15)(REG_READOUT_SROUT_POSNEG_BIT) <= srout_posneg;
  regs_read_arr(15)(REG_READOUT_SROUT_LATENCY_MSB downto REG_READOUT_SROUT_LATENCY_LSB) <= srout_latency;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_DRS_EN_BIT) <= soft_reset_drs_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_DAQ_EN_BIT) <= soft_reset_daq_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_DMA_EN_BIT) <= soft_reset_dma_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_PTR_EN_BIT) <= soft_reset_ptr_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_TRG_EN_BIT) <= soft_reset_trg_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_BUF_EN_BIT) <= soft_reset_buf_en;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DRS_BIT) <= soft_reset_wait_drs;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DAQ_BIT) <= soft_reset_wait_daq;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DMA_BIT) <= soft_reset_wait_dma;
  regs_read_arr(18)(REG_READOUT_SOFT_RESET_DONE_BIT) <= soft_reset_done;
  regs_read_arr(19)(REG_FPGA_DNA_DNA_LSBS_MSB downto REG_FPGA_DNA_DNA_LSBS_LSB) <= dna (31 downto 0);
  regs_read_arr(20)(REG_FPGA_DNA_DNA_MSBS_MSB downto REG_FPGA_DNA_DNA_MSBS_LSB) <= dna (56 downto 32);
  regs_read_arr(21)(REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_LSB) <= std_logic_vector(timestamp (31 downto 0));
  regs_read_arr(22)(REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_LSB) <= std_logic_vector(timestamp (47 downto 32));
  regs_read_arr(23)(REG_FPGA_XADC_CALIBRATION_MSB downto REG_FPGA_XADC_CALIBRATION_LSB) <= calibration;
  regs_read_arr(23)(REG_FPGA_XADC_VCCPINT_MSB downto REG_FPGA_XADC_VCCPINT_LSB) <= vccpint;
  regs_read_arr(24)(REG_FPGA_XADC_VCCPAUX_MSB downto REG_FPGA_XADC_VCCPAUX_LSB) <= vccpaux;
  regs_read_arr(24)(REG_FPGA_XADC_VCCODDR_MSB downto REG_FPGA_XADC_VCCODDR_LSB) <= vccoddr;
  regs_read_arr(25)(REG_FPGA_XADC_TEMP_MSB downto REG_FPGA_XADC_TEMP_LSB) <= temp;
  regs_read_arr(25)(REG_FPGA_XADC_VCCINT_MSB downto REG_FPGA_XADC_VCCINT_LSB) <= vccint;
  regs_read_arr(26)(REG_FPGA_XADC_VCCAUX_MSB downto REG_FPGA_XADC_VCCAUX_LSB) <= vccaux;
  regs_read_arr(26)(REG_FPGA_XADC_VCCBRAM_MSB downto REG_FPGA_XADC_VCCBRAM_LSB) <= vccbram;
  regs_read_arr(27)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB) <= board_id;
  regs_read_arr(28)(REG_FPGA_DRS_TEMP_MSB downto REG_FPGA_DRS_TEMP_LSB) <= drs_temp;
  regs_read_arr(30)(REG_DAQ_DAQ_FRAGMENT_EN_BIT) <= daq_fragment_en;
  regs_read_arr(30)(REG_DAQ_DAQ_BUSY_BIT) <= daq_busy;
  regs_read_arr(32)(REG_TRIGGER_EXT_TRIGGER_EN_BIT) <= ext_trigger_en;
  regs_read_arr(32)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT) <= ext_trigger_active_hi;
  regs_read_arr(32)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT) <= mt_is_level_trigger;
  regs_read_arr(32)(REG_TRIGGER_MT_LINK_ID_MSB downto REG_TRIGGER_MT_LINK_ID_LSB) <= mt_link_id;
  regs_read_arr(33)(REG_TRIGGER_CNT_MT_PRBS_ERRS_MSB downto REG_TRIGGER_CNT_MT_PRBS_ERRS_LSB) <= cnt_mt_prbs_err;
  regs_read_arr(35)(REG_TRIGGER_MT_TRIGGER_MODE_BIT) <= mt_trigger_mode;
  regs_read_arr(36)(REG_TRIGGER_CNT_MT_CRC_ERR_MSB downto REG_TRIGGER_CNT_MT_CRC_ERR_LSB) <= cnt_mt_crc_err;
  regs_read_arr(37)(REG_TRIGGER_TRIGGER_ENABLE_BIT) <= trigger_enable;
  regs_read_arr(38)(REG_TRIGGER_MT_EVENT_CNT_MSB downto REG_TRIGGER_MT_EVENT_CNT_LSB) <= mt_event_cnt;
  regs_read_arr(39)(REG_TRIGGER_MT_TRIGGER_RATE_MSB downto REG_TRIGGER_MT_TRIGGER_RATE_LSB) <= mt_trigger_rate;
  regs_read_arr(40)(REG_COUNTERS_CNT_SEM_CORRECTION_MSB downto REG_COUNTERS_CNT_SEM_CORRECTION_LSB) <= cnt_sem_corrected;
  regs_read_arr(41)(REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB downto REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB) <= cnt_sem_uncorrectable;
  regs_read_arr(42)(REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB) <= cnt_readouts;
  regs_read_arr(43)(REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_LSB) <= dma_packet_counter;
  regs_read_arr(44)(REG_COUNTERS_CNT_LOST_EVENT_MSB downto REG_COUNTERS_CNT_LOST_EVENT_LSB) <= cnt_lost_events;
  regs_read_arr(45)(REG_COUNTERS_CNT_EVENT_MSB downto REG_COUNTERS_CNT_EVENT_LSB) <= event_counter;
  regs_read_arr(46)(REG_COUNTERS_TRIGGER_RATE_MSB downto REG_COUNTERS_TRIGGER_RATE_LSB) <= trigger_rate;
  regs_read_arr(47)(REG_COUNTERS_LOST_TRIGGER_RATE_MSB downto REG_COUNTERS_LOST_TRIGGER_RATE_LSB) <= lost_trigger_rate;
  regs_read_arr(49)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= trig_gen_rate;
  regs_read_arr(50)(REG_HOG_GLOBAL_DATE_MSB downto REG_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
  regs_read_arr(51)(REG_HOG_GLOBAL_TIME_MSB downto REG_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
  regs_read_arr(52)(REG_HOG_GLOBAL_VER_MSB downto REG_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
  regs_read_arr(53)(REG_HOG_GLOBAL_SHA_MSB downto REG_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
  regs_read_arr(54)(REG_HOG_REPO_SHA_MSB downto REG_HOG_REPO_SHA_LSB) <= REPO_SHA;
  regs_read_arr(55)(REG_HOG_TOP_VER_MSB downto REG_HOG_TOP_VER_LSB) <= REPO_VER;
  regs_read_arr(56)(REG_HOG_HOG_SHA_MSB downto REG_HOG_HOG_SHA_LSB) <= HOG_SHA;
  regs_read_arr(57)(REG_HOG_HOG_VER_MSB downto REG_HOG_HOG_VER_LSB) <= HOG_VER;
  regs_read_arr(59)(REG_SPY_DATA_MSB downto REG_SPY_DATA_LSB) <= spy_data;
  regs_read_arr(60)(REG_SPY_FULL_BIT) <= spy_full;
  regs_read_arr(60)(REG_SPY_EMPTY_BIT) <= spy_empty;
  regs_read_arr(63)(REG_DMA_RAM_A_OCCUPANCY_MSB downto REG_DMA_RAM_A_OCCUPANCY_LSB) <= ram_buff_a_occupancy;
  regs_read_arr(64)(REG_DMA_RAM_B_OCCUPANCY_MSB downto REG_DMA_RAM_B_OCCUPANCY_LSB) <= ram_buff_b_occupancy;
  regs_read_arr(65)(REG_DMA_DMA_POINTER_MSB downto REG_DMA_DMA_POINTER_LSB) <= dma_pointer;

  -- Connect write signals
  drs_dmode <= regs_write_arr(0)(REG_CHIP_DMODE_BIT);
  drs_standby_mode <= regs_write_arr(0)(REG_CHIP_STANDBY_MODE_BIT);
  drs_transp_mode <= regs_write_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT);
  chn_config <= regs_write_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB);
  clock_tap_delays <= regs_write_arr(2)(REG_CHIP_CLK_IDELAY_MSB downto REG_CHIP_CLK_IDELAY_LSB);
  cylon_mode <= regs_write_arr(3)(REG_CHIP_CYLON_MODE_BIT);
  drs_ctl_start_timer <= regs_write_arr(3)(REG_CHIP_START_TIMER_MSB downto REG_CHIP_START_TIMER_LSB);
  drs_roi_mode <= regs_write_arr(5)(REG_READOUT_ROI_MODE_BIT);
  adc_latency <= regs_write_arr(5)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB);
  sample_count_max <= regs_write_arr(5)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB);
  drs_spike_removal <= regs_write_arr(5)(REG_READOUT_EN_SPIKE_REMOVAL_BIT);
  readout_mask_axi <= regs_write_arr(6)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB);
  readout_mask_9th_channel_auto <= regs_write_arr(6)(REG_READOUT_AUTO_9TH_CHANNEL_BIT);
  wait_vdd_clocks <= regs_write_arr(13)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB);
  drs_diagnostic_mode <= regs_write_arr(14)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT);
  adc_posneg <= regs_write_arr(15)(REG_READOUT_POSNEG_BIT);
  srout_posneg <= regs_write_arr(15)(REG_READOUT_SROUT_POSNEG_BIT);
  srout_latency <= regs_write_arr(15)(REG_READOUT_SROUT_LATENCY_MSB downto REG_READOUT_SROUT_LATENCY_LSB);
  soft_reset_drs_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_DRS_EN_BIT);
  soft_reset_daq_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_DAQ_EN_BIT);
  soft_reset_dma_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_DMA_EN_BIT);
  soft_reset_ptr_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_PTR_EN_BIT);
  soft_reset_trg_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_TRG_EN_BIT);
  soft_reset_buf_en <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_BUF_EN_BIT);
  soft_reset_wait_drs <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DRS_BIT);
  soft_reset_wait_daq <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DAQ_BIT);
  soft_reset_wait_dma <= regs_write_arr(18)(REG_READOUT_SOFT_RESET_WAIT_DMA_BIT);
  board_id <= regs_write_arr(27)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB);
  drs_temp <= regs_write_arr(28)(REG_FPGA_DRS_TEMP_MSB downto REG_FPGA_DRS_TEMP_LSB);
  daq_fragment_en <= regs_write_arr(30)(REG_DAQ_DAQ_FRAGMENT_EN_BIT);
  ext_trigger_en <= regs_write_arr(32)(REG_TRIGGER_EXT_TRIGGER_EN_BIT);
  ext_trigger_active_hi <= regs_write_arr(32)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT);
  mt_is_level_trigger <= regs_write_arr(32)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT);
  mt_trigger_mode <= regs_write_arr(35)(REG_TRIGGER_MT_TRIGGER_MODE_BIT);
  trigger_enable <= regs_write_arr(37)(REG_TRIGGER_TRIGGER_ENABLE_BIT);
  trig_gen_rate <= regs_write_arr(49)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB);

  -- Connect write pulse signals
  drs_start <= regs_write_pulse_arr(7);
  drs_reinit <= regs_write_pulse_arr(8);
  drs_configure <= regs_write_pulse_arr(9);
  drs_reset <= regs_write_pulse_arr(10);
  daq_reset <= regs_write_pulse_arr(11);
  dma_control_reset <= regs_write_pulse_arr(12);
  dma_clear <= regs_write_pulse_arr(16);
  soft_reset <= regs_write_pulse_arr(17);
  debug_packet_inject <= regs_write_pulse_arr(29);
  force_trig <= regs_write_pulse_arr(31);
  mt_prbs_rst <= regs_write_pulse_arr(34);
  cnt_reset <= regs_write_pulse_arr(48);
  spy_reset <= regs_write_pulse_arr(58);
  ram_a_occ_rst <= regs_write_pulse_arr(61);
  ram_b_occ_rst <= regs_write_pulse_arr(62);
  ram_toggle_request <= regs_write_pulse_arr(66);

  -- Connect write done signals

  -- Connect read pulse signals
  spy_rd_en <= regs_read_pulse_arr(59);

  -- Connect counter instances

  COUNTER_TRIGGER_CNT_MT_PRBS_ERRS : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 32
  )
  port map (
      ref_clk_i => clock,
      reset_i   => mt_prbs_rst,
      en_i      => mt_prbs_err or mt_inactive,
      snap_i    => '1',
      count_o   => cnt_mt_prbs_err
  );


  COUNTER_TRIGGER_CNT_MT_CRC_ERR : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => not mt_crc_ok and mt_crc_valid,
      snap_i    => '1',
      count_o   => cnt_mt_crc_err
  );


  COUNTER_COUNTERS_CNT_SEM_CORRECTION : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => sem_correction,
      snap_i    => '1',
      count_o   => cnt_sem_corrected
  );


  COUNTER_COUNTERS_CNT_SEM_UNCORRECTABLE : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 4
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => sem_uncorrectable_error,
      snap_i    => '1',
      count_o   => cnt_sem_uncorrectable
  );


  COUNTER_COUNTERS_CNT_READOUTS_COMPLETED : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 32
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => readout_complete,
      snap_i    => '1',
      count_o   => cnt_readouts
  );


  COUNTER_COUNTERS_CNT_LOST_EVENT : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 16
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => trigger and drs_busy,
      snap_i    => '1',
      count_o   => cnt_lost_events
  );


  COUNTER_COUNTERS_CNT_EVENT : entity work.counter_snap
  generic map (
      g_COUNTER_WIDTH  => 32
  )
  port map (
      ref_clk_i => clock,
      reset_i   => reset or cnt_reset,
      en_i      => trigger,
      snap_i    => '1',
      count_o   => event_counter
  );


  -- Connect rate instances

  -- Connect read ready signals
    regs_read_ready_arr(59) <= spy_valid;

  -- Defaults
  regs_defaults(0)(REG_CHIP_DMODE_BIT) <= REG_CHIP_DMODE_DEFAULT;
  regs_defaults(0)(REG_CHIP_STANDBY_MODE_BIT) <= REG_CHIP_STANDBY_MODE_DEFAULT;
  regs_defaults(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= REG_CHIP_TRANSPARENT_MODE_DEFAULT;
  regs_defaults(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= REG_CHIP_CHANNEL_CONFIG_DEFAULT;
  regs_defaults(2)(REG_CHIP_CLK_IDELAY_MSB downto REG_CHIP_CLK_IDELAY_LSB) <= REG_CHIP_CLK_IDELAY_DEFAULT;
  regs_defaults(3)(REG_CHIP_CYLON_MODE_BIT) <= REG_CHIP_CYLON_MODE_DEFAULT;
  regs_defaults(3)(REG_CHIP_START_TIMER_MSB downto REG_CHIP_START_TIMER_LSB) <= REG_CHIP_START_TIMER_DEFAULT;
  regs_defaults(5)(REG_READOUT_ROI_MODE_BIT) <= REG_READOUT_ROI_MODE_DEFAULT;
  regs_defaults(5)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= REG_READOUT_ADC_LATENCY_DEFAULT;
  regs_defaults(5)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= REG_READOUT_SAMPLE_COUNT_DEFAULT;
  regs_defaults(5)(REG_READOUT_EN_SPIKE_REMOVAL_BIT) <= REG_READOUT_EN_SPIKE_REMOVAL_DEFAULT;
  regs_defaults(6)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= REG_READOUT_READOUT_MASK_DEFAULT;
  regs_defaults(6)(REG_READOUT_AUTO_9TH_CHANNEL_BIT) <= REG_READOUT_AUTO_9TH_CHANNEL_DEFAULT;
  regs_defaults(13)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB) <= REG_READOUT_WAIT_VDD_CLKS_DEFAULT;
  regs_defaults(14)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT) <= REG_READOUT_DRS_DIAGNOSTIC_MODE_DEFAULT;
  regs_defaults(15)(REG_READOUT_POSNEG_BIT) <= REG_READOUT_POSNEG_DEFAULT;
  regs_defaults(15)(REG_READOUT_SROUT_POSNEG_BIT) <= REG_READOUT_SROUT_POSNEG_DEFAULT;
  regs_defaults(15)(REG_READOUT_SROUT_LATENCY_MSB downto REG_READOUT_SROUT_LATENCY_LSB) <= REG_READOUT_SROUT_LATENCY_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_DRS_EN_BIT) <= REG_READOUT_SOFT_RESET_DRS_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_DAQ_EN_BIT) <= REG_READOUT_SOFT_RESET_DAQ_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_DMA_EN_BIT) <= REG_READOUT_SOFT_RESET_DMA_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_PTR_EN_BIT) <= REG_READOUT_SOFT_RESET_PTR_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_TRG_EN_BIT) <= REG_READOUT_SOFT_RESET_TRG_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_BUF_EN_BIT) <= REG_READOUT_SOFT_RESET_BUF_EN_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_WAIT_DRS_BIT) <= REG_READOUT_SOFT_RESET_WAIT_DRS_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_WAIT_DAQ_BIT) <= REG_READOUT_SOFT_RESET_WAIT_DAQ_DEFAULT;
  regs_defaults(18)(REG_READOUT_SOFT_RESET_WAIT_DMA_BIT) <= REG_READOUT_SOFT_RESET_WAIT_DMA_DEFAULT;
  regs_defaults(27)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB) <= REG_FPGA_BOARD_ID_DEFAULT;
  regs_defaults(28)(REG_FPGA_DRS_TEMP_MSB downto REG_FPGA_DRS_TEMP_LSB) <= REG_FPGA_DRS_TEMP_DEFAULT;
  regs_defaults(30)(REG_DAQ_DAQ_FRAGMENT_EN_BIT) <= REG_DAQ_DAQ_FRAGMENT_EN_DEFAULT;
  regs_defaults(32)(REG_TRIGGER_EXT_TRIGGER_EN_BIT) <= REG_TRIGGER_EXT_TRIGGER_EN_DEFAULT;
  regs_defaults(32)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT) <= REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_DEFAULT;
  regs_defaults(32)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT) <= REG_TRIGGER_MT_TRIGGER_IS_LEVEL_DEFAULT;
  regs_defaults(35)(REG_TRIGGER_MT_TRIGGER_MODE_BIT) <= REG_TRIGGER_MT_TRIGGER_MODE_DEFAULT;
  regs_defaults(37)(REG_TRIGGER_TRIGGER_ENABLE_BIT) <= REG_TRIGGER_TRIGGER_ENABLE_DEFAULT;
  regs_defaults(49)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= REG_TRIG_GEN_RATE_DEFAULT;

  -- Define writable regs
  regs_writable_arr(0) <= '1';
  regs_writable_arr(2) <= '1';
  regs_writable_arr(3) <= '1';
  regs_writable_arr(5) <= '1';
  regs_writable_arr(6) <= '1';
  regs_writable_arr(13) <= '1';
  regs_writable_arr(14) <= '1';
  regs_writable_arr(15) <= '1';
  regs_writable_arr(18) <= '1';
  regs_writable_arr(27) <= '1';
  regs_writable_arr(28) <= '1';
  regs_writable_arr(30) <= '1';
  regs_writable_arr(32) <= '1';
  regs_writable_arr(35) <= '1';
  regs_writable_arr(37) <= '1';
  regs_writable_arr(49) <= '1';

  -- --==== Registers end ============================================================================

end Behavioral;
