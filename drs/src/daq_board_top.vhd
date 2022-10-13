----------------------------------------------------------------------------------
-- DRS DAQ Board Top
-- GAPS DRS4 Readout Firmware
-- I. Garcia, A. Peck, S. Quinn
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.ipbus_pkg.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library unisim;
use unisim.vcomponents.all;

entity top_readout_board is
  generic (
    EN_TMR_IPB_SLAVE_DRS : integer := 0;

    CLK_FREQUENCY : integer := 15000000;

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
    emio_scl          : inout std_logic;
    emio_sda          : inout std_logic

    -- gpio_p : inout std_logic_vector (9 downto 0);
    -- gpio_n : inout std_logic_vector (9 downto 0)

    );
end top_readout_board;

architecture Behavioral of top_readout_board is

  signal clk33  : std_logic;
  signal clock  : std_logic;
  signal locked : std_logic;

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
  signal drs_dwrite       : std_logic;

  signal drs_dwrite_delay_sel : std_logic_vector (11 downto 0) := (others => '0');

  -- Trigger Signals
  signal trigger               : std_logic := '0';
  signal posneg                : std_logic := '0';
  signal ext_trigger_active_hi : std_logic := '0';
  signal mt_trigger_i          : std_logic := '0';
  signal ext_trigger_en        : std_logic := '0';
  signal force_trig            : std_logic := '0';
  signal mt_is_level_trigger   : std_logic := '0';
  signal mt_level_trigger      : std_logic := '0';

  signal trigger_rate      : std_logic_vector (31 downto 0) := (others => '0');
  signal lost_trigger_rate : std_logic_vector (31 downto 0) := (others => '0');

  signal trig_gen_rate : std_logic_vector (31 downto 0) := (others => '0');
  signal trig_gen      : std_logic                      := '0';
  signal cnt_reset     : std_logic                      := '0';

  -- DAQ
  signal daq_busy            : std_logic := '0';
  signal debug_packet_inject : std_logic;

  signal drs_srclk_en            : std_logic;
  signal sem_correction          : std_logic;
  signal sem_uncorrectable_error : std_logic;

  -------------------------------------------------------------------------------
  -- DRS configuration
  -------------------------------------------------------------------------------

  signal drs_diagnostic_mode : std_logic := '0';

  signal resync        : std_logic := '0';
  signal drs_busy      : std_logic;
  signal roi_mode      : std_logic;
  signal spike_removal : std_logic;
  signal dmode         : std_logic;
  signal reinit        : std_logic;
  signal configure     : std_logic;
  signal standby_mode  : std_logic;
  signal start         : std_logic;
  signal transp_mode   : std_logic;

  signal wait_vdd_clocks : std_logic_vector (15 downto 0);

  signal readout_mask                  : std_logic_vector (9*2-1 downto 0);
  signal readout_mask_axi              : std_logic_vector (8 downto 0) := (others => '0');
  signal readout_mask_trig             : std_logic_vector (8 downto 0) := (others => '0');
  signal readout_mask_or               : std_logic_vector (8 downto 0) := (others => '0');
  signal readout_mask_9th_channel_auto : std_logic;
  signal read_ch8, read_ch17           : std_logic                     := '0';

  signal drs_reset        : std_logic;
  signal daq_reset        : std_logic;
  signal drs_config       : std_logic_vector (7 downto 0);
  signal chn_config       : std_logic_vector (7 downto 0);
  signal drs_stop_cell    : std_logic_vector (9 downto 0);
  signal dna              : std_logic_vector (56 downto 0);
  signal board_id         : std_logic_vector (7 downto 0);
  signal adc_latency      : std_logic_vector (5 downto 0);
  signal sample_count_max : std_logic_vector (9 downto 0);

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
  signal daq_data  : std_logic_vector (13 downto 0);
  signal daq_valid : std_logic := '0';
  signal daq_empty : std_logic := '0';

  signal fifo_data_out : std_logic_vector (15 downto 0);
  signal fifo_data_wen : std_logic;
  --fifo_fifo_busy : in std_logic;

  signal dma_packet_counter : std_logic_vector(31 downto 0);
  signal dma_control_reset  : std_logic := '0';
  signal dma_clear          : std_logic := '0';

  signal calibration : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpint     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccpaux     : std_logic_vector(11 downto 0) := (others => '0');
  signal vccoddr     : std_logic_vector(11 downto 0) := (others => '0');
  signal temp        : std_logic_vector(11 downto 0) := (others => '0');
  signal vccint      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccaux      : std_logic_vector(11 downto 0) := (others => '0');
  signal vccbram     : std_logic_vector(11 downto 0) := (others => '0');

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
    signal cnt_sem_corrected : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_sem_uncorrectable : std_logic_vector (3 downto 0) := (others => '0');
    signal cnt_readouts : std_logic_vector (31 downto 0) := (others => '0');
    signal cnt_lost_events : std_logic_vector (15 downto 0) := (others => '0');
    signal event_counter : std_logic_vector (31 downto 0) := (others => '0');
    signal gfp_eventid_timeout_cnt : std_logic_vector (15 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------

  signal gfp_use_eventid      : std_logic;
  signal gfp_eventid_rx       : std_logic_vector (31 downto 0);
  signal gfp_eventid_rx_valid : std_logic;
  signal gfp_eventid          : std_logic_vector (31 downto 0);
  signal gfp_eventid_valid    : std_logic;
  signal gfp_eventid_read     : std_logic;
  signal gfp_eventid_timeout  : std_logic;

  --IPbus
  signal ipb_reset    : std_logic;
  signal ipb_clk      : std_logic;
  signal ipb_miso_arr : ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
  signal ipb_mosi_arr : ipb_wbus_array(IPB_SLAVES - 1 downto 0);


  component device_dna
    port(
      clock : in  std_logic;
      reset : in  std_logic;
      dna   : out std_logic_vector
      );
  end component;

  component drs
    port(
      clock                    : in  std_logic;
      reset                    : in  std_logic;
      diagnostic_mode          : in  std_logic;
      trigger_i                : in  std_logic;
      posneg_i                 : in  std_logic;
      adc_data_i               : in  std_logic_vector;
      drs_ctl_spike_removal    : in  std_logic;
      drs_ctl_roi_mode         : in  std_logic;
      drs_ctl_dmode            : in  std_logic;
      drs_ctl_adc_latency      : in  std_logic_vector;
      drs_ctl_sample_count_max : in  std_logic_vector;
      drs_ctl_config           : in  std_logic_vector;
      drs_ctl_standby_mode     : in  std_logic;
      drs_ctl_transp_mode      : in  std_logic;
      drs_ctl_start            : in  std_logic;
      drs_ctl_reinit           : in  std_logic;
      drs_ctl_configure_drs    : in  std_logic;
      drs_ctl_chn_config       : in  std_logic_vector;
      drs_ctl_readout_mask_i   : in  std_logic_vector;
      drs_ctl_wait_vdd_clocks  : in  std_logic_vector;
      drs_srout_i              : in  std_logic;
      drs_addr_o               : out std_logic_vector;
      drs_nreset_o             : out std_logic;
      drs_denable_o            : out std_logic;
      drs_dwrite_o             : out std_logic;
      drs_rsrload_o            : out std_logic;
      drs_srclk_en_o           : out std_logic;
      drs_srin_o               : out std_logic;
      drs_on_o                 : out std_logic;
      drs_stop_cell_o          : out std_logic_vector(9 downto 0);
      fifo_wdata_o             : out std_logic_vector;
      fifo_wen_o               : out std_logic;
      readout_complete         : out std_logic;
      busy_o                   : out std_logic
      );
  end component;

  component clock_wizard
    port (
      -- Clock out ports
      drs_clk   : out std_logic;
      trg_clk   : out std_logic;
      daq_clk   : out std_logic;
      -- Status and control signals
      locked    : out std_logic;
      -- Clock in ports
      clk_in1_p : in  std_logic;
      clk_in1_n : in  std_logic
      );
  end component;

begin

  ---- TODO: do this outside the drs module for TMR
  ------ take data in on negedge of clock, assuming that adc and fpga clocks are synchronous
  --process (clock) is
  --begin
  --  if (falling_edge(clock)) then
  --    adc_data_iob <= adc_data_i;
  --  end if;
  --end process;

  ---- transfer on flops from negedge to posedge before fifo
  --process (clock) is
  --begin
  --  if (rising_edge(clock)) then
  --    adc_data <= adc_data_iob;
  --  end if;
  --end process;

  -------------------------------------------------------------------------------
  -- MMCM / PLL
  -------------------------------------------------------------------------------

  clock_wizard_inst : clock_wizard
    port map (
      drs_clk   => clk33,
      trg_clk   => open,
      daq_clk   => open,
      locked    => locked,
      clk_in1_p => clock_i_p,
      clk_in1_n => clock_i_n
      );

  reset <= not locked;
  clock <= clk33;

  -------------------------------------------------------------------------------
  -- Trigger Input
  -------------------------------------------------------------------------------

  gfp_spi_rx : entity work.spi_rx
    port map (
      clock   => clock,
      sclk    => gfp_sclk,
      sdat    => gfp_sdat,
      data_o  => gfp_eventid_rx,
      valid_o => gfp_eventid_rx_valid
      );

  -- process to latch the SPI received event ID and send up a valid flag the
  -- flag and latched data will remain high until the daq reads out the event
  --
  -- when the daq reads from the gfp event id, it asserts "gfp_eventid_read"
  -- which will de-assert the valid flag and re-arm for another readout

  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (gfp_eventid_read = '1') then
        gfp_eventid_valid <= '0';
        gfp_eventid <= x"FFFFFFFD";
      -- don't overwrite existing triggers until they are already read
      elsif (gfp_eventid_valid = '0' and gfp_eventid_rx_valid = '1') then
        gfp_eventid_valid <= '1';
        gfp_eventid       <= gfp_eventid_rx;
      end if;

    end if;
  end process;


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
  -- Trigger output
  --------------------------------------------------------------------------------

  drs_dwrite <= drs_dwrite_sync and drs_dwrite_async;

  trigger_mux_inst : entity work.trigger_mux
    generic map (TRIGGER_OS_MAX => 3)
    port map (
      clock => clock,

      ext_trigger_i         => ext_trigger_i or mt_level_trigger,
      ext_trigger_en        => ext_trigger_en,
      ext_trigger_active_hi => ext_trigger_active_hi,

      force_trig => force_trig or trig_gen,

      delay_i => drs_dwrite_delay_sel,

      master_trigger => '0',

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
      if (reset = '1' or resync = '1') then
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
  readout_mask_or <= readout_mask_trig or readout_mask_axi;

  -- TODO: this needs to be expanded when there are two drs chips
  read_ch8 <= readout_mask_9th_channel_auto and or_reduce(readout_mask_or (7 downto 0));
--read_ch17 <= readout_mask_9th_channel_auto and or_reduce(readout_mask_or (16 downto 9));

  -- TODO: this needs to be expanded when there are two drs chips
  readout_mask <= '0' & x"00" & (readout_mask_or or (read_ch8 & x"00"));  -- or (read_ch17 & '1' & x"00");

  drs_config(0) <= dmode;
  drs_config(1) <= '1';                 -- pllen
  drs_config(2) <= '0';                 -- wrsloop

  drs_inst : drs
    port map (
      clock     => clock,
      reset     => reset or drs_reset,
      trigger_i => trigger,
      posneg_i  => posneg,

      --adc_data => adc_data,
      adc_data_i => adc_data_i,

      diagnostic_mode => drs_diagnostic_mode,

      drs_ctl_roi_mode         => roi_mode,  -- 1 bit roi input
      drs_ctl_dmode            => dmode,     -- 1 bit dmode input
      drs_ctl_config           => drs_config(7 downto 0),
      drs_ctl_standby_mode     => standby_mode,
      drs_ctl_transp_mode      => transp_mode,
      drs_ctl_start            => start,
      drs_ctl_adc_latency      => adc_latency,
      drs_ctl_spike_removal    => spike_removal,
      drs_ctl_sample_count_max => sample_count_max,
      drs_ctl_reinit           => reinit,
      drs_ctl_configure_drs    => configure,
      drs_ctl_chn_config       => chn_config(7 downto 0),
      drs_ctl_readout_mask_i   => readout_mask (8 downto 0),
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

      busy_o => drs_busy

      );

  -------------------------------------------------------------------------------
  -- DAQ
  -------------------------------------------------------------------------------

  daq_fifo_inst : entity work.fifo_sync
    generic map (
      DEPTH    => 1024,
      WR_WIDTH => 14,
      RD_WIDTH => 14,
      read_mode => "fwft"
      )
    port map (
      rst    => reset,
      clk    => clock,                  -- daq_clock
      wr_en  => drs_data_valid,
      rd_en  => drs_rden,
      din    => drs_data,
      dout   => daq_data,
      valid  => daq_valid,
      full   => open,
      empty  => daq_empty
      );

  daq_inst : entity work.daq
    port map (
      clock                 => clock,
      reset                 => daq_reset or reset,
      debug_packet_inject_i => debug_packet_inject,
      temperature_i         => temp,
      trigger_i             => trigger,
      stop_cell_i           => drs_stop_cell,
      event_cnt_i           => event_counter,

      gfp_use_eventid_i     => gfp_use_eventid,
      gfp_eventid_i         => gfp_eventid,
      gfp_eventid_valid_i   => gfp_eventid_valid,
      gfp_eventid_read_o    => gfp_eventid_read,
      gfp_eventid_timeout_o => gfp_eventid_timeout,

      mask_i      => readout_mask,
      board_id    => board_id,
      sync_err_i  => '0',
      dna_i       => "0000000" & dna,
      hash_i      => GLOBAL_SHA,
      timestamp_i => std_logic_vector(timestamp),
      roi_size_i  => sample_count_max,
      dtap0_i     => dtap_cnt,
      dtap1_i     => (others => '0'),

      drs_busy_i  => '0', -- FIXME
      drs_data_i  => drs_data,
      drs_valid_i => drs_data_valid,
      drs_rden_o  => drs_rden,

      data_o      => fifo_data_out,
      valid_o     => fifo_data_wen,
      busy_o      => daq_busy,
      done_o      => readout_complete
      );

  -------------------------------------------------------------------------------
  -- Spybuffer
  -------------------------------------------------------------------------------

  -- fifo to read data through the "spybuffer"
  spy_fifo_inst : entity work.fifo_async
    generic map (
      DEPTH    => 2*16384,
      WR_WIDTH => 16,
      RD_WIDTH => 16
      )
    port map (
      rst    => spy_reset,
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

  --------------------------------------------------------------------------------
  -- Trigger generator
  --------------------------------------------------------------------------------

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

      packet_counter    => dma_packet_counter,
      dma_control_reset => dma_control_reset,
      dma_clear         => dma_clear,

      clk33          => clock,
      pl_mmcm_locked => locked,

      ipb_reset    => ipb_reset,
      ipb_clk      => ipb_clk,
      ipb_miso_arr => ipb_miso_arr,
      ipb_mosi_arr => ipb_mosi_arr,

      -- DMA
      dma_reset_i => reset,
      daq_busy_in => daq_busy,

      -- RAM occupancy monitoring
      ram_a_occ_rst_i        => ram_a_occ_rst,
      ram_b_occ_rst_i        => ram_b_occ_rst,
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
    regs_addresses(2)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"10";
    regs_addresses(3)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"11";
    regs_addresses(4)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"12";
    regs_addresses(5)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"13";
    regs_addresses(6)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"14";
    regs_addresses(7)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"15";
    regs_addresses(8)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"16";
    regs_addresses(9)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"17";
    regs_addresses(10)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"18";
    regs_addresses(11)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"19";
    regs_addresses(12)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1a";
    regs_addresses(13)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1b";
    regs_addresses(14)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"20";
    regs_addresses(15)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"21";
    regs_addresses(16)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"24";
    regs_addresses(17)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"25";
    regs_addresses(18)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"26";
    regs_addresses(19)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"27";
    regs_addresses(20)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"28";
    regs_addresses(21)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"29";
    regs_addresses(22)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"2a";
    regs_addresses(23)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"30";
    regs_addresses(24)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"40";
    regs_addresses(25)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"41";
    regs_addresses(26)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"42";
    regs_addresses(27)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"50";
    regs_addresses(28)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"51";
    regs_addresses(29)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"52";
    regs_addresses(30)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"53";
    regs_addresses(31)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"54";
    regs_addresses(32)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"55";
    regs_addresses(33)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"56";
    regs_addresses(34)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"57";
    regs_addresses(35)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"58";
    regs_addresses(36)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"59";
    regs_addresses(37)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"60";
    regs_addresses(38)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"61";
    regs_addresses(39)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"62";
    regs_addresses(40)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"63";
    regs_addresses(41)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"64";
    regs_addresses(42)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"65";
    regs_addresses(43)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"66";
    regs_addresses(44)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"67";
    regs_addresses(45)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"70";
    regs_addresses(46)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"71";
    regs_addresses(47)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"72";
    regs_addresses(48)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"00";
    regs_addresses(49)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"01";
    regs_addresses(50)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"02";
    regs_addresses(51)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"03";
    regs_addresses(52)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"04";
    regs_addresses(53)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"05";
    regs_addresses(54)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"00";
    regs_addresses(55)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"01";
    regs_addresses(56)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"02";

    -- Connect read signals
    regs_read_arr(0)(REG_CHIP_DMODE_BIT) <= dmode;
    regs_read_arr(0)(REG_CHIP_STANDBY_MODE_BIT) <= standby_mode;
    regs_read_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= transp_mode;
    regs_read_arr(0)(REG_CHIP_DRS_PLL_LOCK_BIT) <= drs_plllock_i;
    regs_read_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= chn_config;
    regs_read_arr(1)(REG_CHIP_DTAP_FREQ_MSB downto REG_CHIP_DTAP_FREQ_LSB) <= dtap_cnt;
    regs_read_arr(2)(REG_READOUT_ROI_MODE_BIT) <= roi_mode;
    regs_read_arr(2)(REG_READOUT_BUSY_BIT) <= drs_busy;
    regs_read_arr(2)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= adc_latency;
    regs_read_arr(2)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= sample_count_max;
    regs_read_arr(2)(REG_READOUT_EN_SPIKE_REMOVAL_BIT) <= spike_removal;
    regs_read_arr(3)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= readout_mask_axi;
    regs_read_arr(3)(REG_READOUT_AUTO_9TH_CHANNEL_BIT) <= readout_mask_9th_channel_auto;
    regs_read_arr(10)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB) <= wait_vdd_clocks;
    regs_read_arr(11)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT) <= drs_diagnostic_mode;
    regs_read_arr(12)(REG_READOUT_POSNEG_BIT) <= posneg;
    regs_read_arr(14)(REG_FPGA_DNA_DNA_LSBS_MSB downto REG_FPGA_DNA_DNA_LSBS_LSB) <= dna (31 downto 0);
    regs_read_arr(15)(REG_FPGA_DNA_DNA_MSBS_MSB downto REG_FPGA_DNA_DNA_MSBS_LSB) <= dna (56 downto 32);
    regs_read_arr(16)(REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_LSB) <= std_logic_vector(timestamp (31 downto 0));
    regs_read_arr(17)(REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_LSB) <= std_logic_vector(timestamp (47 downto 32));
    regs_read_arr(18)(REG_FPGA_XADC_CALIBRATION_MSB downto REG_FPGA_XADC_CALIBRATION_LSB) <= calibration;
    regs_read_arr(18)(REG_FPGA_XADC_VCCPINT_MSB downto REG_FPGA_XADC_VCCPINT_LSB) <= vccpint;
    regs_read_arr(19)(REG_FPGA_XADC_VCCPAUX_MSB downto REG_FPGA_XADC_VCCPAUX_LSB) <= vccpaux;
    regs_read_arr(19)(REG_FPGA_XADC_VCCODDR_MSB downto REG_FPGA_XADC_VCCODDR_LSB) <= vccoddr;
    regs_read_arr(20)(REG_FPGA_XADC_TEMP_MSB downto REG_FPGA_XADC_TEMP_LSB) <= temp;
    regs_read_arr(20)(REG_FPGA_XADC_VCCINT_MSB downto REG_FPGA_XADC_VCCINT_LSB) <= vccint;
    regs_read_arr(21)(REG_FPGA_XADC_VCCAUX_MSB downto REG_FPGA_XADC_VCCAUX_LSB) <= vccaux;
    regs_read_arr(21)(REG_FPGA_XADC_VCCBRAM_MSB downto REG_FPGA_XADC_VCCBRAM_LSB) <= vccbram;
    regs_read_arr(22)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB) <= board_id;
    regs_read_arr(25)(REG_TRIGGER_EXT_TRIGGER_EN_BIT) <= ext_trigger_en;
    regs_read_arr(25)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT) <= ext_trigger_active_hi;
    regs_read_arr(25)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT) <= mt_is_level_trigger;
    regs_read_arr(26)(REG_TRIGGER_TRIGGER_DELAY_MSB downto REG_TRIGGER_TRIGGER_DELAY_LSB) <= drs_dwrite_delay_sel;
    regs_read_arr(27)(REG_COUNTERS_CNT_SEM_CORRECTION_MSB downto REG_COUNTERS_CNT_SEM_CORRECTION_LSB) <= cnt_sem_corrected;
    regs_read_arr(28)(REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB downto REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB) <= cnt_sem_uncorrectable;
    regs_read_arr(29)(REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB) <= cnt_readouts;
    regs_read_arr(30)(REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_LSB) <= dma_packet_counter;
    regs_read_arr(31)(REG_COUNTERS_CNT_LOST_EVENT_MSB downto REG_COUNTERS_CNT_LOST_EVENT_LSB) <= cnt_lost_events;
    regs_read_arr(32)(REG_COUNTERS_CNT_EVENT_MSB downto REG_COUNTERS_CNT_EVENT_LSB) <= event_counter;
    regs_read_arr(33)(REG_COUNTERS_TRIGGER_RATE_MSB downto REG_COUNTERS_TRIGGER_RATE_LSB) <= trigger_rate;
    regs_read_arr(34)(REG_COUNTERS_LOST_TRIGGER_RATE_MSB downto REG_COUNTERS_LOST_TRIGGER_RATE_LSB) <= lost_trigger_rate;
    regs_read_arr(36)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= trig_gen_rate;
    regs_read_arr(37)(REG_HOG_GLOBAL_DATE_MSB downto REG_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
    regs_read_arr(38)(REG_HOG_GLOBAL_TIME_MSB downto REG_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
    regs_read_arr(39)(REG_HOG_GLOBAL_VER_MSB downto REG_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
    regs_read_arr(40)(REG_HOG_GLOBAL_SHA_MSB downto REG_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
    regs_read_arr(41)(REG_HOG_TOP_SHA_MSB downto REG_HOG_TOP_SHA_LSB) <= TOP_SHA;
    regs_read_arr(42)(REG_HOG_TOP_VER_MSB downto REG_HOG_TOP_VER_LSB) <= TOP_VER;
    regs_read_arr(43)(REG_HOG_HOG_SHA_MSB downto REG_HOG_HOG_SHA_LSB) <= HOG_SHA;
    regs_read_arr(44)(REG_HOG_HOG_VER_MSB downto REG_HOG_HOG_VER_LSB) <= HOG_VER;
    regs_read_arr(46)(REG_SPY_DATA_MSB downto REG_SPY_DATA_LSB) <= spy_data;
    regs_read_arr(47)(REG_SPY_FULL_BIT) <= spy_full;
    regs_read_arr(47)(REG_SPY_EMPTY_BIT) <= spy_empty;
    regs_read_arr(50)(REG_DMA_RAM_A_OCCUPANCY_MSB downto REG_DMA_RAM_A_OCCUPANCY_LSB) <= ram_buff_a_occupancy;
    regs_read_arr(51)(REG_DMA_RAM_B_OCCUPANCY_MSB downto REG_DMA_RAM_B_OCCUPANCY_LSB) <= ram_buff_b_occupancy;
    regs_read_arr(52)(REG_DMA_DMA_POINTER_MSB downto REG_DMA_DMA_POINTER_LSB) <= dma_pointer;
    regs_read_arr(54)(REG_GFP_EVENTID_SPI_EN_BIT) <= gfp_use_eventid;
    regs_read_arr(55)(REG_GFP_EVENTID_RX_MSB downto REG_GFP_EVENTID_RX_LSB) <= gfp_eventid_rx;
    regs_read_arr(56)(REG_GFP_EVENTID_TIMEOUT_CNT_MSB downto REG_GFP_EVENTID_TIMEOUT_CNT_LSB) <= gfp_eventid_timeout_cnt;

    -- Connect write signals
    dmode <= regs_write_arr(0)(REG_CHIP_DMODE_BIT);
    standby_mode <= regs_write_arr(0)(REG_CHIP_STANDBY_MODE_BIT);
    transp_mode <= regs_write_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT);
    chn_config <= regs_write_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB);
    roi_mode <= regs_write_arr(2)(REG_READOUT_ROI_MODE_BIT);
    adc_latency <= regs_write_arr(2)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB);
    sample_count_max <= regs_write_arr(2)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB);
    spike_removal <= regs_write_arr(2)(REG_READOUT_EN_SPIKE_REMOVAL_BIT);
    readout_mask_axi <= regs_write_arr(3)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB);
    readout_mask_9th_channel_auto <= regs_write_arr(3)(REG_READOUT_AUTO_9TH_CHANNEL_BIT);
    wait_vdd_clocks <= regs_write_arr(10)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB);
    drs_diagnostic_mode <= regs_write_arr(11)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT);
    posneg <= regs_write_arr(12)(REG_READOUT_POSNEG_BIT);
    board_id <= regs_write_arr(22)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB);
    ext_trigger_en <= regs_write_arr(25)(REG_TRIGGER_EXT_TRIGGER_EN_BIT);
    ext_trigger_active_hi <= regs_write_arr(25)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT);
    mt_is_level_trigger <= regs_write_arr(25)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT);
    drs_dwrite_delay_sel <= regs_write_arr(26)(REG_TRIGGER_TRIGGER_DELAY_MSB downto REG_TRIGGER_TRIGGER_DELAY_LSB);
    trig_gen_rate <= regs_write_arr(36)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB);
    gfp_use_eventid <= regs_write_arr(54)(REG_GFP_EVENTID_SPI_EN_BIT);

    -- Connect write pulse signals
    start <= regs_write_pulse_arr(4);
    reinit <= regs_write_pulse_arr(5);
    configure <= regs_write_pulse_arr(6);
    drs_reset <= regs_write_pulse_arr(7);
    daq_reset <= regs_write_pulse_arr(8);
    dma_control_reset <= regs_write_pulse_arr(9);
    dma_clear <= regs_write_pulse_arr(13);
    debug_packet_inject <= regs_write_pulse_arr(23);
    force_trig <= regs_write_pulse_arr(24);
    cnt_reset <= regs_write_pulse_arr(35);
    spy_reset <= regs_write_pulse_arr(45);
    ram_a_occ_rst <= regs_write_pulse_arr(48);
    ram_b_occ_rst <= regs_write_pulse_arr(49);
    ram_toggle_request <= regs_write_pulse_arr(53);

    -- Connect write done signals

    -- Connect read pulse signals
    spy_rd_en <= regs_read_pulse_arr(46);

    -- Connect counter instances

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


    COUNTER_GFP_EVENTID_TIMEOUT_CNT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock,
        reset_i   => reset or cnt_reset,
        en_i      => gfp_eventid_timeout,
        snap_i    => '1',
        count_o   => gfp_eventid_timeout_cnt
    );


    -- Connect rate instances

    -- Connect read ready signals
    regs_read_ready_arr(46) <= spy_valid;

    -- Defaults
    regs_defaults(0)(REG_CHIP_DMODE_BIT) <= REG_CHIP_DMODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_STANDBY_MODE_BIT) <= REG_CHIP_STANDBY_MODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= REG_CHIP_TRANSPARENT_MODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= REG_CHIP_CHANNEL_CONFIG_DEFAULT;
    regs_defaults(2)(REG_READOUT_ROI_MODE_BIT) <= REG_READOUT_ROI_MODE_DEFAULT;
    regs_defaults(2)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= REG_READOUT_ADC_LATENCY_DEFAULT;
    regs_defaults(2)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= REG_READOUT_SAMPLE_COUNT_DEFAULT;
    regs_defaults(2)(REG_READOUT_EN_SPIKE_REMOVAL_BIT) <= REG_READOUT_EN_SPIKE_REMOVAL_DEFAULT;
    regs_defaults(3)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= REG_READOUT_READOUT_MASK_DEFAULT;
    regs_defaults(3)(REG_READOUT_AUTO_9TH_CHANNEL_BIT) <= REG_READOUT_AUTO_9TH_CHANNEL_DEFAULT;
    regs_defaults(10)(REG_READOUT_WAIT_VDD_CLKS_MSB downto REG_READOUT_WAIT_VDD_CLKS_LSB) <= REG_READOUT_WAIT_VDD_CLKS_DEFAULT;
    regs_defaults(11)(REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT) <= REG_READOUT_DRS_DIAGNOSTIC_MODE_DEFAULT;
    regs_defaults(12)(REG_READOUT_POSNEG_BIT) <= REG_READOUT_POSNEG_DEFAULT;
    regs_defaults(22)(REG_FPGA_BOARD_ID_MSB downto REG_FPGA_BOARD_ID_LSB) <= REG_FPGA_BOARD_ID_DEFAULT;
    regs_defaults(25)(REG_TRIGGER_EXT_TRIGGER_EN_BIT) <= REG_TRIGGER_EXT_TRIGGER_EN_DEFAULT;
    regs_defaults(25)(REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT) <= REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_DEFAULT;
    regs_defaults(25)(REG_TRIGGER_MT_TRIGGER_IS_LEVEL_BIT) <= REG_TRIGGER_MT_TRIGGER_IS_LEVEL_DEFAULT;
    regs_defaults(26)(REG_TRIGGER_TRIGGER_DELAY_MSB downto REG_TRIGGER_TRIGGER_DELAY_LSB) <= REG_TRIGGER_TRIGGER_DELAY_DEFAULT;
    regs_defaults(36)(REG_TRIG_GEN_RATE_MSB downto REG_TRIG_GEN_RATE_LSB) <= REG_TRIG_GEN_RATE_DEFAULT;
    regs_defaults(54)(REG_GFP_EVENTID_SPI_EN_BIT) <= REG_GFP_EVENTID_SPI_EN_DEFAULT;

    -- Define writable regs
    regs_writable_arr(0) <= '1';
    regs_writable_arr(2) <= '1';
    regs_writable_arr(3) <= '1';
    regs_writable_arr(10) <= '1';
    regs_writable_arr(11) <= '1';
    regs_writable_arr(12) <= '1';
    regs_writable_arr(22) <= '1';
    regs_writable_arr(25) <= '1';
    regs_writable_arr(26) <= '1';
    regs_writable_arr(36) <= '1';
    regs_writable_arr(54) <= '1';

  -- --==== Registers end ============================================================================

end Behavioral;
