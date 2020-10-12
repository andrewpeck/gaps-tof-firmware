-- TODO: ADC clock phase??
-- TODO: ADC setup/hold constraints
-- Data outputs are available one propagation delay (tPD = 2ns -- 6ns)
-- after the rising edge of the clock signal.

library work;
use work.ipbus_pkg.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity drs_top is
  generic (
    EN_TMR_IPB_SLAVE_DRS : integer := 1;

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

    trigger_i_p : in std_logic;
    trigger_i_n : in std_logic;

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

    gpio_p : inout std_logic_vector (10 downto 0);
    gpio_n : inout std_logic_vector (10 downto 0)

    );
end drs_top;

architecture Behavioral of drs_top is

  signal clk33  : std_logic;
  signal clock  : std_logic;
  signal locked : std_logic;
  signal reset  : std_logic;
  signal dma_reset  : std_logic := '0';

  --signal adc_data, adc_data_iob : std_logic_vector (13 downto 0) := (others => '0');

  signal drs_data            : std_logic_vector (13 downto 0);
  signal drs_data_valid      : std_logic;
  signal daq_busy            : std_logic := '0';
  signal trigger             : std_logic := '0';
  signal force_trig          : std_logic := '0';
  signal debug_packet_inject : std_logic;

  signal drs_srclk_en            : std_logic;
  signal sem_correction          : std_logic;
  signal sem_classification      : std_logic;
  signal sem_uncorrectable_error : std_logic;

  signal drs_plllock : std_logic := '0';
  signal drs_dtap    : std_logic := '0';

  ------------------------------------------------------------------------------------------------------------------------
  -- DRS configuration
  ------------------------------------------------------------------------------------------------------------------------

  signal resync       : std_logic;
  signal busy         : std_logic;
  signal roi_mode     : std_logic;
  signal dmode        : std_logic;
  signal reinit       : std_logic;
  signal configure    : std_logic;
  signal standby_mode : std_logic;
  signal start        : std_logic;
  signal transp_mode  : std_logic;

  signal readout_mask     : std_logic_vector (7 downto 0);
  signal drs_reset        : std_logic;
  signal daq_reset        : std_logic;
  signal drs_config       : std_logic_vector (7 downto 0);
  signal chn_config       : std_logic_vector (7 downto 0);
  signal dna              : std_logic_vector (56 downto 0);
  signal adc_latency      : std_logic_vector (5 downto 0);
  signal sample_count_max : std_logic_vector (9 downto 0);

  signal timestamp : unsigned (47 downto 0) := (others => '0');

  signal dtap_high_cnt : unsigned (24 downto 0) := (others => '0');
  signal dtap_low_cnt  : unsigned (24 downto 0) := (others => '0');

  signal dtap_high_cnt_reg : std_logic_vector (24 downto 0) := (others => '0');
  signal dtap_low_cnt_reg  : std_logic_vector (24 downto 0) := (others => '0');

  signal dtap_last : std_logic := '0';

  signal readout_complete : std_logic;

  -- Read data (send to axi stream etc)
  signal rd_data   : std_logic_vector (15 downto 0);
  signal rd_enable : std_logic := '1';
  signal rd_clock  : std_logic;

  signal spy_data  : std_logic_vector (31 downto 0) := (others => '0');
  signal spy_full  : std_logic                      := '0';
  signal spy_empty : std_logic                      := '0';
  signal spy_reset : std_logic                      := '0';
  signal spy_rd_en : std_logic                      := '0';
  signal spy_valid : std_logic                      := '0';

  -- ADC Readout
  signal fifo_data_out : std_logic_vector (15 downto 0);
  signal fifo_data_wen : std_logic;
  --fifo_fifo_busy : in std_logic;

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
    signal cnt_readouts : std_logic_vector (15 downto 0) := (others => '0');
    signal cnt_lost_events : std_logic_vector (15 downto 0) := (others => '0');
    signal event_counter : std_logic_vector (31 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------


  --IPbus
  signal ipb_reset    : std_logic;
  signal ipb_clk      : std_logic;
  signal ipb_miso_arr : ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
  signal ipb_mosi_arr : ipb_wbus_array(IPB_SLAVES - 1 downto 0);

  signal wrsloop : std_logic;
  signal pllen   : std_logic;

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
      trigger_i                : in  std_logic;
      adc_data_i               : in  std_logic_vector;
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
      fifo_wdata_o             : out std_logic_vector;
      fifo_wen_o               : out std_logic;
      fifo_clock_o             : out std_logic;
      readout_complete         : out std_logic;
      busy_o                   : out std_logic
      );
  end component;

  component clock_wizard
    port
      (                                 -- Clock in ports
        -- Clock out ports
        drs_clk   : out std_logic;
        trg_clk   : out std_logic;
        daq_clk   : out std_logic;
        -- Status and control signals
        locked    : out std_logic;
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

  ------------------------------------------------------------------------------------------------------------------------
  -- MMCM / PLL
  ------------------------------------------------------------------------------------------------------------------------

  clock_wizard_inst : clock_wizard
    port map (
      drs_clk   => clk33,
      trg_clk   => open,
      daq_clk   => open,
      locked    => locked,
      clk_in1_p => clock_i_p,
      clk_in1_n => clock_i_n
      );

  clock    <= clk33;
  rd_clock <= clk33;

  -----------------------------------------------------------------------------------------------------------------------
  -- Trigger Input
  -----------------------------------------------------------------------------------------------------------------------

  --    ibuftrigger : IBUFDS
  --    generic map (                 --
  --        DIFF_TERM    => TRUE,   -- Differential Termination
  --        IBUF_LOW_PWR => TRUE    -- Low power="TRUE", Highest performance="FALSE"
  --    )
  --    port map (
  --        O  => trigger_i,   -- Buffer output
  --        I  => trigger_i_p, -- Diff_p buffer input (connect directly to top-level port)
  --        IB => trigger_i_n  -- Diff_n buffer input (connect directly to top-level port)
  --    );

  process (clock)
  begin
    if (rising_edge(clock)) then
      trigger <= force_trig;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- DTAP Monitoring
  --------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then

      drs_dtap <= drs_dtap_i;

      --    For this purpose the DTAP signal is available, which toggles
      --    its state each time the domino wave reaches cell #512. If
      --    operating the chip at f DOMINO , the DTAP outputs a rectan-
      --    gular signal with 50% duty cycle with a frequency ac-
      --    cording to following formula:
      --    DOMINO DTAP
      --    f = 1/2048 * f_domino =

      dtap_last <= drs_dtap;

      -- high state counter
      if (drs_dtap = '1') then
        dtap_high_cnt <= dtap_high_cnt + 1;
      else
        dtap_high_cnt <= (others => '0');
      end if;

      -- latch high state counter on falling edge
      if (drs_dtap = '0' and dtap_last = '1') then
        dtap_high_cnt_reg <= std_logic_vector(dtap_high_cnt);
      end if;

      -- low state counter
      if (drs_dtap = '0') then
        dtap_low_cnt <= dtap_low_cnt + 1;
      else
        dtap_low_cnt <= (others => '0');
      end if;

      -- latch low state counter on rising edge
      if (drs_dtap = '1' and dtap_last = '0') then
        dtap_low_cnt_reg <= std_logic_vector(dtap_low_cnt);
      end if;

    end if;
  end process;

  -----------------------------------------------------------------------------------------------------------------------
  -- SRCLK ODDR
  -----------------------------------------------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------------------------------------------------
  -- inputs
  ------------------------------------------------------------------------------------------------------------------------

  process (clock)
  begin
    if (rising_edge(clock)) then
      drs_plllock <= drs_plllock_i;
      drs_dtap    <= drs_dtap_i;
      reset       <= not locked;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------------------------------
  -- Timestamp
  ------------------------------------------------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------------------------------------------------
  -- DRS Control Module
  ------------------------------------------------------------------------------------------------------------------------

  wrsloop <= '0';
  pllen   <= '1';

  drs_config(0) <= dmode;
  drs_config(1) <= pllen;
  drs_config(2) <= wrsloop;

  drs_inst : drs
    port map (
      clock     => clock,
      reset     => reset or drs_reset,
      trigger_i => trigger,

      --adc_data => adc_data,
      adc_data_i => adc_data_i,

      drs_ctl_roi_mode         => roi_mode,  -- 1 bit roi input
      drs_ctl_dmode            => dmode,     -- 1 bit dmode input
      drs_ctl_config           => drs_config(7 downto 0),
      drs_ctl_standby_mode     => standby_mode,
      drs_ctl_transp_mode      => transp_mode,
      drs_ctl_start            => start,
      drs_ctl_adc_latency      => adc_latency,
      drs_ctl_sample_count_max => sample_count_max,
      drs_ctl_reinit           => reinit,
      drs_ctl_configure_drs    => configure,
      drs_ctl_chn_config       => chn_config(7 downto 0),
      drs_ctl_readout_mask_i   => readout_mask(7 downto 0),
      drs_ctl_wait_vdd_clocks  => x"4000",

      drs_srout_i => drs_srout_i,

      drs_addr_o     => drs_addr_o(3 downto 0),
      drs_nreset_o   => drs_nreset_o,
      drs_denable_o  => drs_denable_o,
      drs_dwrite_o   => drs_dwrite_o,
      drs_rsrload_o  => drs_rsrload_o,
      drs_srclk_en_o => drs_srclk_en,
      drs_srin_o     => drs_srin_o,


      fifo_wdata_o => drs_data,
      fifo_wen_o   => drs_data_valid,
      fifo_clock_o => open,

      readout_complete => open,

      busy_o => busy

      );

  daq_inst : entity work.daq
    generic map (
      g_DRS_ID    => 0,
      g_WORD_SIZE => 16
      )
    port map (
      clock                 => clock,
      reset                 => daq_reset or reset,
      debug_packet_inject_i => debug_packet_inject,
      trigger_i             => trigger,
      event_cnt_i           => event_counter,
      mask_i                => x"00" & readout_mask,
      board_id              => (others => '0'),
      sync_err_i            => '0',
      dna_i                 => "0000000" & dna,
      hash_i                => GLOBAL_SHA,
      timestamp_i           => std_logic_vector(timestamp),
      roi_size_i            => to_slv(1023, 10),  -- TODO: connect to ipbus, make all of this count from 0
      drs_busy_i            => busy,
      drs_data_i            => drs_data(13 downto 0),
      drs_valid_i           => drs_data_valid,
      data_o                => fifo_data_out,
      valid_o               => fifo_data_wen,
      busy_o                => daq_busy,
      done_o                => readout_complete
      );

  spy_fifo_inst : entity work.fifo_async
    generic map (
      DEPTH    => 16384,
      WR_WIDTH => 16,
      RD_WIDTH => 32
      )
    port map (
      rst     => spy_reset,
      wr_clk  => clock,                 -- daq_clock
      rd_clk  => clock,
      wr_en   => fifo_data_wen,
      rd_en   => spy_rd_en,
      din     => fifo_data_out,
      dout    => spy_data,
      valid   => spy_valid,
      full    => spy_full,
      empty   => spy_empty,
      sbiterr => open,
      dbiterr => open
      );

  --trigger_delay trigger_delay (
  --clock => clock,
  --coarse_delay => coarse_delay,
  --d  => ,
  --q  =>
  --);

  ------------------------------------------------------------------------------------------------------------------------
  -- Soft Error Mitigation
  ------------------------------------------------------------------------------------------------------------------------

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

  ------------------------------------------------------------------------------------------------------------------------
  -- Device DNA
  ------------------------------------------------------------------------------------------------------------------------

  device_dna_inst : device_dna
    port map(
      clock => clock,
      reset => reset,
      dna   => dna
      );

  ------------------------------------------------------------------------------------------------------------------------
  -- Interface to processing system for DMA, AXI, etc...
  ------------------------------------------------------------------------------------------------------------------------

  ps_interface_inst : entity work.ps_interface
    port map (
      fixed_io_mio      => fixed_io_mio,
      fixed_io_ddr_vrn  => fixed_io_ddr_vrn,
      fixed_io_ddr_vrp  => fixed_io_ddr_vrp,
      fixed_io_ps_srstb => fixed_io_ps_srstb,
      fixed_io_ps_clk   => fixed_io_ps_clk,
      fixed_io_ps_porb  => fixed_io_ps_porb,
      ddr_cas_n         => ddr_cas_n,
      ddr_cke           => ddr_cke,
      ddr_ck_n          => ddr_ck_n,
      ddr_ck_p          => ddr_ck_p,
      ddr_cs_n          => ddr_cs_n,
      ddr_reset_n       => ddr_reset_n,
      ddr_odt           => ddr_odt,
      ddr_ras_n         => ddr_ras_n,
      ddr_we_n          => ddr_we_n,
      ddr_ba            => ddr_ba,
      ddr_addr          => ddr_addr,
      ddr_dm            => ddr_dm,
      ddr_dq            => ddr_dq,
      ddr_dqs_n         => ddr_dqs_n,
      ddr_dqs_p         => ddr_dqs_p,

      fifo_data_in  => fifo_data_out,
      fifo_clock_in => clock, -- TODO: separate daq clock
      fifo_data_wen => fifo_data_wen,

      clk33 => clock,
      pl_mmcm_locked => locked,

      ipb_reset    => ipb_reset,
      ipb_clk      => ipb_clk,
      ipb_miso_arr => ipb_miso_arr,
      ipb_mosi_arr => ipb_mosi_arr,

      dma_reset => dma_reset
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
    regs_addresses(0)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "000" & x"0";
    regs_addresses(1)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "000" & x"1";
    regs_addresses(2)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "000" & x"2";
    regs_addresses(3)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"0";
    regs_addresses(4)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"1";
    regs_addresses(5)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"2";
    regs_addresses(6)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"3";
    regs_addresses(7)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"4";
    regs_addresses(8)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"5";
    regs_addresses(9)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "001" & x"6";
    regs_addresses(10)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "010" & x"0";
    regs_addresses(11)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "010" & x"1";
    regs_addresses(12)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "010" & x"4";
    regs_addresses(13)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "010" & x"5";
    regs_addresses(14)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "011" & x"0";
    regs_addresses(15)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "100" & x"0";
    regs_addresses(16)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "101" & x"0";
    regs_addresses(17)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "101" & x"1";
    regs_addresses(18)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "101" & x"2";
    regs_addresses(19)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "101" & x"3";
    regs_addresses(20)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "101" & x"4";
    regs_addresses(21)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"0";
    regs_addresses(22)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"1";
    regs_addresses(23)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"2";
    regs_addresses(24)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"3";
    regs_addresses(25)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"4";
    regs_addresses(26)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"5";
    regs_addresses(27)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"6";
    regs_addresses(28)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "110" & x"7";
    regs_addresses(29)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "111" & x"0";
    regs_addresses(30)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "111" & x"1";
    regs_addresses(31)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "111" & x"2";

    -- Connect read signals
    regs_read_arr(0)(REG_CHIP_DMODE_BIT) <= dmode;
    regs_read_arr(0)(REG_CHIP_STANDBY_MODE_BIT) <= standby_mode;
    regs_read_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= transp_mode;
    regs_read_arr(0)(REG_CHIP_DRS_PLL_LOCK_BIT) <= drs_plllock;
    regs_read_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= chn_config;
    regs_read_arr(1)(REG_CHIP_DTAP_HIGH_CNTS_MSB downto REG_CHIP_DTAP_HIGH_CNTS_LSB) <= dtap_high_cnt_reg;
    regs_read_arr(2)(REG_CHIP_DTAP_LOW_CNTS_MSB downto REG_CHIP_DTAP_LOW_CNTS_LSB) <= dtap_low_cnt_reg;
    regs_read_arr(3)(REG_READOUT_ROI_MODE_BIT) <= roi_mode;
    regs_read_arr(3)(REG_READOUT_BUSY_BIT) <= busy;
    regs_read_arr(3)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= adc_latency;
    regs_read_arr(3)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= sample_count_max;
    regs_read_arr(4)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= readout_mask;
    regs_read_arr(10)(REG_FPGA_DNA_DNA_LSBS_MSB downto REG_FPGA_DNA_DNA_LSBS_LSB) <= dna (31 downto 0);
    regs_read_arr(11)(REG_FPGA_DNA_DNA_MSBS_MSB downto REG_FPGA_DNA_DNA_MSBS_LSB) <= dna (56 downto 32);
    regs_read_arr(12)(REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_LSB) <= std_logic_vector(timestamp (31 downto 0));
    regs_read_arr(13)(REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_MSB downto REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_LSB) <= std_logic_vector(timestamp (47 downto 32));
    regs_read_arr(16)(REG_COUNTERS_CNT_SEM_CORRECTION_MSB downto REG_COUNTERS_CNT_SEM_CORRECTION_LSB) <= cnt_sem_corrected;
    regs_read_arr(17)(REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB downto REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB) <= cnt_sem_uncorrectable;
    regs_read_arr(18)(REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB) <= cnt_readouts;
    regs_read_arr(19)(REG_COUNTERS_CNT_LOST_EVENT_MSB downto REG_COUNTERS_CNT_LOST_EVENT_LSB) <= cnt_lost_events;
    regs_read_arr(20)(REG_COUNTERS_CNT_EVENT_MSB downto REG_COUNTERS_CNT_EVENT_LSB) <= event_counter;
    regs_read_arr(21)(REG_HOG_GLOBAL_DATE_MSB downto REG_HOG_GLOBAL_DATE_LSB) <= GLOBAL_DATE;
    regs_read_arr(22)(REG_HOG_GLOBAL_TIME_MSB downto REG_HOG_GLOBAL_TIME_LSB) <= GLOBAL_TIME;
    regs_read_arr(23)(REG_HOG_GLOBAL_VER_MSB downto REG_HOG_GLOBAL_VER_LSB) <= GLOBAL_VER;
    regs_read_arr(24)(REG_HOG_GLOBAL_SHA_MSB downto REG_HOG_GLOBAL_SHA_LSB) <= GLOBAL_SHA;
    regs_read_arr(25)(REG_HOG_TOP_SHA_MSB downto REG_HOG_TOP_SHA_LSB) <= TOP_SHA;
    regs_read_arr(26)(REG_HOG_TOP_VER_MSB downto REG_HOG_TOP_VER_LSB) <= TOP_VER;
    regs_read_arr(27)(REG_HOG_HOG_SHA_MSB downto REG_HOG_HOG_SHA_LSB) <= HOG_SHA;
    regs_read_arr(28)(REG_HOG_HOG_VER_MSB downto REG_HOG_HOG_VER_LSB) <= HOG_VER;
    regs_read_arr(30)(REG_SPY_DATA_MSB downto REG_SPY_DATA_LSB) <= spy_data;
    regs_read_arr(31)(REG_SPY_FULL_BIT) <= spy_full;
    regs_read_arr(31)(REG_SPY_EMPTY_BIT) <= spy_empty;

    -- Connect write signals
    dmode <= regs_write_arr(0)(REG_CHIP_DMODE_BIT);
    standby_mode <= regs_write_arr(0)(REG_CHIP_STANDBY_MODE_BIT);
    transp_mode <= regs_write_arr(0)(REG_CHIP_TRANSPARENT_MODE_BIT);
    chn_config <= regs_write_arr(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB);
    roi_mode <= regs_write_arr(3)(REG_READOUT_ROI_MODE_BIT);
    adc_latency <= regs_write_arr(3)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB);
    sample_count_max <= regs_write_arr(3)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB);
    readout_mask <= regs_write_arr(4)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB);

    -- Connect write pulse signals
    start <= regs_write_pulse_arr(5);
    reinit <= regs_write_pulse_arr(6);
    configure <= regs_write_pulse_arr(7);
    drs_reset <= regs_write_pulse_arr(8);
    daq_reset <= regs_write_pulse_arr(9);
    debug_packet_inject <= regs_write_pulse_arr(14);
    force_trig <= regs_write_pulse_arr(15);
    spy_reset <= regs_write_pulse_arr(29);

    -- Connect write done signals

    -- Connect read pulse signals
    spy_rd_en <= regs_read_pulse_arr(30);

    -- Connect counter instances

    COUNTER_COUNTERS_CNT_SEM_CORRECTION : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock,
        reset_i   => ipb_reset,
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
        reset_i   => ipb_reset,
        en_i      => sem_uncorrectable_error,
        snap_i    => '1',
        count_o   => cnt_sem_uncorrectable
    );


    COUNTER_COUNTERS_CNT_READOUTS_COMPLETED : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        ref_clk_i => clock,
        reset_i   => ipb_reset,
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
        reset_i   => ipb_reset,
        en_i      => trigger and busy,
        snap_i    => '1',
        count_o   => cnt_lost_events
    );


    COUNTER_COUNTERS_CNT_EVENT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 32
    )
    port map (
        ref_clk_i => clock,
        reset_i   => ipb_reset,
        en_i      => trigger,
        snap_i    => '1',
        count_o   => event_counter
    );


    -- Connect rate instances

    -- Connect read ready signals
    regs_read_ready_arr(30) <= spy_valid;

    -- Defaults
    regs_defaults(0)(REG_CHIP_DMODE_BIT) <= REG_CHIP_DMODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_STANDBY_MODE_BIT) <= REG_CHIP_STANDBY_MODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_TRANSPARENT_MODE_BIT) <= REG_CHIP_TRANSPARENT_MODE_DEFAULT;
    regs_defaults(0)(REG_CHIP_CHANNEL_CONFIG_MSB downto REG_CHIP_CHANNEL_CONFIG_LSB) <= REG_CHIP_CHANNEL_CONFIG_DEFAULT;
    regs_defaults(3)(REG_READOUT_ROI_MODE_BIT) <= REG_READOUT_ROI_MODE_DEFAULT;
    regs_defaults(3)(REG_READOUT_ADC_LATENCY_MSB downto REG_READOUT_ADC_LATENCY_LSB) <= REG_READOUT_ADC_LATENCY_DEFAULT;
    regs_defaults(3)(REG_READOUT_SAMPLE_COUNT_MSB downto REG_READOUT_SAMPLE_COUNT_LSB) <= REG_READOUT_SAMPLE_COUNT_DEFAULT;
    regs_defaults(4)(REG_READOUT_READOUT_MASK_MSB downto REG_READOUT_READOUT_MASK_LSB) <= REG_READOUT_READOUT_MASK_DEFAULT;

    -- Define writable regs
    regs_writable_arr(0) <= '1';
    regs_writable_arr(3) <= '1';
    regs_writable_arr(4) <= '1';

  --==== Registers end ============================================================================

end Behavioral;
