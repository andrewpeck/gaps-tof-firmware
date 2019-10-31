-- TODO: ADC clock phase??
-- TODO: ADC setup/hold constraints
-- Data outputs are available one propagation delay (tPD = 2ns -- 6ns) after the rising edge of the clock signal.

library work;
use work.ipbus_pkg.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

entity drs_top is
port (

    -- 33MHz ADC clock
    clock_i_p : in std_logic;
    clock_i_n : in std_logic;

    -- Data pins from ADC
    adc_data_i : in std_logic_vector (13 downto 0);

    -- DRS IO
    drs_srout_i : in std_logic;                        -- Multiplexed Shift Register Outpu
    drs_addr_o    : out std_logic_vector (3 downto 0); -- Address Bit Inputs
    drs_denable_o : out std_logic;                     -- Domino Enable Input. A low-to-high transition starts the Domino Wave. Set-ting this input low stops the Domino Wave.
    drs_dwrite_o  : out std_logic;                     -- Domino Write Input. Connects the Domino Wave Circuit to the Sampling Cells to enable sampling if high.
    drs_rsrload_o : out std_logic;                     -- Read Shift Register Load Input
    drs_srclk_o   : out std_logic;                     -- Multiplexed Shift Register Clock Input
    drs_srin_o    : out std_logic;                     -- Shared Shift Register Input
    drs_nreset_o  : out std_logic;                     --
    drs_plllock_i : in std_logic;                      --
    drs_dtap_i    : in std_logic;                      --

    trigger_i_p : in std_logic;
    trigger_i_n : in std_logic;

    gpio_p : inout std_logic_vector (10 downto 0);
    gpio_n : inout std_logic_vector (10 downto 0);

    -- ADC Readout
    fifo_data_out  : out std_logic_vector (15 downto 0);
    fifo_clock_out : out std_logic;
    fifo_data_wen :  out std_logic;
    --fifo_fifo_busy : in std_logic;

    -- AXI For Slow Control
    S_AXI_LITE_ACLK    : in std_logic;
    S_AXI_LITE_ARESETN : in std_logic;
    S_AXI_LITE_AWADDR  : in std_logic_vector (C_IPB_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_AWPROT  : in std_logic_vector (2 downto 0);
    S_AXI_LITE_AWVALID : in std_logic;
    S_AXI_LITE_AWREADY : out std_logic;
    S_AXI_LITE_WDATA   : in std_logic_vector (C_IPB_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_WSTRB   : in std_logic_vector((32/8)-1 downto 0); -- 32 = C_S_AXI_DATA_WIDTH
    S_AXI_LITE_WVALID  : in std_logic;
    S_AXI_LITE_WREADY  : out std_logic;
    S_AXI_LITE_BRESP   : out std_logic_vector (1 downto 0);
    S_AXI_LITE_BVALID  : out std_logic;
    S_AXI_LITE_BREADY  : in std_logic;
    S_AXI_LITE_ARADDR  : in std_logic_vector (C_IPB_AXI_ADDR_WIDTH-1 downto 0);
    S_AXI_LITE_ARPROT  : in std_logic_vector (2 downto 0);
    S_AXI_LITE_ARVALID : in std_logic;
    S_AXI_LITE_ARREADY : out std_logic;
    S_AXI_LITE_RDATA   : out std_logic_vector (C_IPB_AXI_DATA_WIDTH-1 downto 0);
    S_AXI_LITE_RRESP   : out std_logic_vector(1 downto 0);
    S_AXI_LITE_RVALID  : out std_logic;
    S_AXI_LITE_RREADY  : in std_logic
);
end drs_top;

architecture Behavioral of drs_top is

    signal clk33  : std_logic;
    signal clk264 : std_logic;
    signal clock : std_logic;
    signal locked : std_logic;
    signal reset : std_logic;

    signal trigger : std_logic := '0';
    signal trigger_i : std_logic;

    signal drs_srclk_en : std_logic;
    signal sem_correction : std_logic;
    signal sem_classification : std_logic;
    signal sem_uncorrectable_error : std_logic;

    signal drs_plllock : std_logic := '0';
    signal drs_dtap : std_logic := '0';

    ------------------------------------------------------------------------------------------------------------------------
    -- DRS configuration
    ------------------------------------------------------------------------------------------------------------------------

    constant MAJOR_VERSION          : std_logic_vector(7 downto 0) := x"00";
    constant MINOR_VERSION          : std_logic_vector(7 downto 0) := x"00";
    constant RELEASE_VERSION        : std_logic_vector(7 downto 0) := x"00";

    constant RELEASE_YEAR           : std_logic_vector(15 downto 0) := x"2019";
    constant RELEASE_MONTH          : std_logic_vector(7 downto  0) := x"06";
    constant RELEASE_DAY            : std_logic_vector(7 downto  0) := x"11";

    ------------------------------------------------------------------------------------------------------------------------
    -- DRS configuration
    ------------------------------------------------------------------------------------------------------------------------

    signal resync           : std_logic;
    signal busy             : std_logic;
    signal roi_mode         : std_logic;
    signal dmode            : std_logic;
    signal reinit           : std_logic;
    signal configure        : std_logic;
    signal standby_mode     : std_logic;
    signal start            : std_logic;
    signal transp_mode      : std_logic;

    signal readout_mask     : std_logic_vector (8 downto 0);
    signal drs_reset        : std_logic;
    signal drs_config       : std_logic_vector (7 downto 0);
    signal chn_config       : std_logic_vector (7 downto 0);
    signal dna              : std_logic_vector (56 downto 0);
    signal adc_latency      : std_logic_vector (5 downto 0);
    signal sample_count_max : std_logic_vector (10 downto 0);

    signal timestamp        : unsigned         (47 downto 0) := (others => '0');

    signal dtap_high_cnt    : unsigned         (24 downto 0) := (others => '0');
    signal dtap_low_cnt     : unsigned         (24 downto 0) := (others => '0');

    signal dtap_high_cnt_reg : std_logic_vector (24 downto 0) := (others => '0');
    signal dtap_low_cnt_reg  : std_logic_vector (24 downto 0) := (others => '0');

    signal dtap_last        : std_logic := '0';

    signal readout_complete : std_logic;


    ------------------------------------------------------------------------------------------------------------------------
    -- Read data (send to axi stream etc)
    ------------------------------------------------------------------------------------------------------------------------


    signal rd_data : std_logic_vector (15 downto 0);
    signal rd_enable : std_logic := '1';
    signal rd_clock : std_logic;

    ------ Register signals begin (this section is generated by generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_write_arr       : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_addresses       : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_defaults        : t_std32_array(REG_DRS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_write_arr_sump  : std_logic_vector(REG_DRS_NUM_REGS - 1 downto 0);
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

    -------------------------- AXI-IPbus bridge ---------------------------------
    --AXI
    signal axi_clk      : std_logic;
    signal axi_reset    : std_logic;
    signal ipb_axi_mosi : t_axi_lite_mosi;
    signal ipb_axi_miso : t_axi_lite_miso;
    --IPbus
    signal ipb_reset    : std_logic;
    signal ipb_clk      : std_logic;
    signal ipb_miso_arr : ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    signal ipb_mosi_arr : ipb_wbus_array(IPB_SLAVES - 1 downto 0);

begin


    S_AXI_LITE_ARREADY <= ipb_axi_miso.arready;                                   -- out
    S_AXI_LITE_AWREADY <= ipb_axi_miso.awready;                                   -- out
    S_AXI_LITE_BRESP   <= ipb_axi_miso.bresp;                                     -- out
    S_AXI_LITE_BVALID  <= ipb_axi_miso.bvalid;                                    -- out
    S_AXI_LITE_RDATA   <= ipb_axi_miso.rdata;                                     -- out
    S_AXI_LITE_RVALID  <= ipb_axi_miso.rvalid;                                    -- out
    S_AXI_LITE_RRESP   <= ipb_axi_miso.rresp                                     ; -- out
    S_AXI_LITE_WREADY  <= ipb_axi_miso.wready; -- out

    ipb_axi_mosi.araddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0) <=S_AXI_LITE_ARADDR  ; -- out
    ipb_axi_mosi.wvalid                                    <= S_AXI_LITE_WVALID  ; -- in
    axi_clk                                                <= S_AXI_LITE_ACLK    ; -- in
    axi_reset                                              <= S_AXI_LITE_ARESETN ; -- in
    ipb_axi_mosi.wdata                                     <= S_AXI_LITE_WDATA   ; -- in
    ipb_axi_mosi.arprot                                    <= S_AXI_LITE_ARPROT  ; -- in
    ipb_axi_mosi.arvalid                                   <= S_AXI_LITE_ARVALID ; -- in
    ipb_axi_mosi.awaddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0) <= S_AXI_LITE_AWADDR  ; -- in
    ipb_axi_mosi.awprot                                    <= S_AXI_LITE_AWPROT  ; -- in
    ipb_axi_mosi.awvalid                                   <= S_AXI_LITE_AWVALID ; -- in
    ipb_axi_mosi.bready                                    <= S_AXI_LITE_BREADY  ; -- in
    ipb_axi_mosi.rready                                    <= S_AXI_LITE_RREADY  ; -- in
    ipb_axi_mosi.wstrb                                     <= S_AXI_LITE_WSTRB   ; -- in

------------------------------------------------------------------------------------------------------------------------
-- MMCM / PLL
------------------------------------------------------------------------------------------------------------------------

    clock_wizard : entity work.clock_wizard
    port map (
        clk33     => clk33,
        clk264    => clk264,
        locked    => locked,
        clk_in1_p => clock_i_p,
        clk_in1_n => clock_i_n
    );


    clock <= clk33;
    rd_clock <= clk33;
-----------------------------------------------------------------------------------------------------------------------
-- Trigger Input
-----------------------------------------------------------------------------------------------------------------------

    ibuftrigger : IBUFDS
    generic map (                 --
        DIFF_TERM    => TRUE,   -- Differential Termination
        IBUF_LOW_PWR => TRUE    -- Low power="TRUE", Highest performance="FALSE"
    )
    port map (
        O  => trigger_i,   -- Buffer output
        I  => trigger_i_p, -- Diff_p buffer input (connect directly to top-level port)
        IB => trigger_i_n  -- Diff_n buffer input (connect directly to top-level port)
    );

    process (clock) begin
    if (rising_edge(clock)) then

        drs_plllock <= drs_plllock;

        drs_dtap    <= drs_dtap_i;

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
            dtap_high_cnt    <= dtap_high_cnt + 1;
        else
            dtap_high_cnt    <= (others => '0');
        end if;

        -- latch high state counter on falling edge
        if (drs_dtap = '0' and dtap_last = '1') then
            dtap_high_cnt_reg <=  std_logic_vector(dtap_high_cnt);
        end if;

        -- low state counter
        if (drs_dtap = '0') then
            dtap_low_cnt    <= dtap_low_cnt + 1;
        else
            dtap_low_cnt    <= (others => '0');
        end if;

        -- latch low state counter on rising edge
        if (drs_dtap = '1' and dtap_last = '0') then
            dtap_low_cnt_reg <= std_logic_vector(dtap_low_cnt);
        end if;

        trigger     <= trigger_i;

    end if;
    end process;

-----------------------------------------------------------------------------------------------------------------------
-- SRCLK ODDR
-----------------------------------------------------------------------------------------------------------------------

    -- put srclk on an oddr
    drs_srclk_oddr : ODDR
    generic map (                        --
        DDR_CLK_EDGE => "OPPOSITE_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
        INIT         => '0',             -- Initial value of Q: 1'b0 or 1'b1
        SRTYPE       => "SYNC"           -- Set/Reset type: "SYNC" or "ASYNC"
    )
    port map (
        Q  => drs_srclk_o,      -- 1-bit DDR output
        C  => clock,            -- 1-bit clock input
        CE => '1',              -- 1-bit clock enable input
        D1 => '1',              -- 1-bit data input (positive edge)
        D2 => '0',              -- 1-bit data input (negative edge)
        R  => not drs_srclk_en, -- 1-bit reset
        S  => '0'               -- 1-bit set
    );

------------------------------------------------------------------------------------------------------------------------
-- inputs
------------------------------------------------------------------------------------------------------------------------


    process (clock) begin
    if (rising_edge(clock)) then

        drs_plllock <= drs_plllock;
        drs_dtap    <= drs_dtap;

    end if;
    end process;

------------------------------------------------------------------------------------------------------------------------
-- Timestamp
------------------------------------------------------------------------------------------------------------------------

    process (clock) begin
    if (rising_edge(clock)) then

        if (reset='1' or resync='1') then
            timestamp <= (others => '0');
        else
            timestamp <= timestamp + 1;
        end if;

    end if;
    end process;

------------------------------------------------------------------------------------------------------------------------
-- DRS Control Module
------------------------------------------------------------------------------------------------------------------------

    drs : entity work.drs
    port map  (

        clock                      => clock,
        reset                      => reset or drs_reset,
        trigger_i                  => trigger,
        timestamp_i                => std_logic_vector(timestamp),
        dna_i                      => dna(15 downto 0),
        event_counter_i            => event_counter,

        adc_data_i                 => adc_data_i,

        drs_ctl_roi_mode           => roi_mode, -- 1 bit roi input
        drs_ctl_dmode              => dmode, -- 1 bit dmode input
        drs_ctl_config             => drs_config(7 downto 0),
        drs_ctl_standby_mode       => standby_mode,
        drs_ctl_transp_mode        => transp_mode,
        drs_ctl_start              => start,
        drs_ctl_adc_latency        => adc_latency,
        drs_ctl_sample_count_max   => sample_count_max,
        drs_ctl_reinit             => reinit,
        drs_ctl_configure_drs      => configure,
        drs_ctl_chn_config         => chn_config(7 downto 0),
        drs_ctl_readout_mask       => readout_mask(8 downto 0),

        drs_srout_i                => drs_srout_i,

        drs_addr_o                 => drs_addr_o(3 downto 0),
        drs_nreset_o               => drs_nreset_o,
        drs_denable_o              => drs_denable_o,
        drs_dwrite_o               => drs_dwrite_o,
        drs_rsrload_o              => drs_rsrload_o,
        drs_srclk_en_o             => drs_srclk_en,
        drs_srin_o                 => drs_srin_o,

        fifo_wdata_o               =>  fifo_data_out(15 downto 0),
        fifo_wen_o                 =>  fifo_data_wen,
        fifo_clock_o               =>  fifo_clock_out,

        readout_complete           => readout_complete,

        busy_o                     => busy

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
        clk_i             => clock,
        correction_o      => sem_correction,
        classification_o  => open,
        uncorrectable_o   => sem_uncorrectable_error,
        heartbeat_o       => open,
        initialization_o  => open,
        observation_o     => open,
        essential_o       => open,
        sump              => open
    );

------------------------------------------------------------------------------------------------------------------------
-- Device DNA in case it is useful
------------------------------------------------------------------------------------------------------------------------

    device_dna : entity work.device_dna
    port map(
        clock => clock,
        reset => reset,
        dna  => dna
    );

------------------------------------------------------------------------------------------------------------------------
-- AXI IPBus (Wishbone) Bridge
------------------------------------------------------------------------------------------------------------------------

    i_axi_ipbus_bridge : entity work.axi_ipbus_bridge
    generic map(
        C_NUM_IPB_SLAVES   => IPB_SLAVES,
        C_S_AXI_DATA_WIDTH => C_IPB_AXI_DATA_WIDTH,
        C_S_AXI_ADDR_WIDTH => C_IPB_AXI_ADDR_WIDTH
    )
    port map(
        ipb_reset_o   => ipb_reset,
        ipb_clk_o     => ipb_clk,
        ipb_miso_i    => ipb_miso_arr,
        ipb_mosi_o    => ipb_mosi_arr,
        S_AXI_ACLK    => axi_clk,
        S_AXI_ARESETN => axi_reset,
        S_AXI_ARADDR  => ipb_axi_mosi.araddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
        S_AXI_ARPROT  => ipb_axi_mosi.arprot,
        S_AXI_ARREADY => ipb_axi_miso.arready,
        S_AXI_ARVALID => ipb_axi_mosi.arvalid,
        S_AXI_AWADDR  => ipb_axi_mosi.awaddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
        S_AXI_AWPROT  => ipb_axi_mosi.awprot,
        S_AXI_AWREADY => ipb_axi_miso.awready,
        S_AXI_AWVALID => ipb_axi_mosi.awvalid,
        S_AXI_BREADY  => ipb_axi_mosi.bready,
        S_AXI_BRESP   => ipb_axi_miso.bresp,
        S_AXI_BVALID  => ipb_axi_miso.bvalid,
        S_AXI_RDATA   => ipb_axi_miso.rdata,
        S_AXI_RRESP   => ipb_axi_miso.rresp,
        S_AXI_RVALID  => ipb_axi_miso.rvalid,
        S_AXI_WDATA   => ipb_axi_mosi.wdata,
        S_AXI_WREADY  => ipb_axi_miso.wready,
        S_AXI_WVALID  => ipb_axi_mosi.wvalid,
        S_AXI_WSTRB   => ipb_axi_mosi.wstrb,
        S_AXI_RREADY  => ipb_axi_mosi.rready
    );

    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    -- BEWARE: AUTO GENERATED CODE LIES BELOW
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------
    ------------------------------------------------------------------------------------------------------------------------

    --===============================================================================================
    -- (this section is generated by tools/generate_registers.py -- do not edit)
    --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave
        generic map(
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
    regs_addresses(0)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"0";
    regs_addresses(1)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"1";
    regs_addresses(2)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "00" & x"2";
    regs_addresses(3)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"0";
    regs_addresses(4)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"1";
    regs_addresses(5)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"2";
    regs_addresses(6)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"3";
    regs_addresses(7)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"4";
    regs_addresses(8)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "01" & x"5";
    regs_addresses(9)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"0";
    regs_addresses(10)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"1";
    regs_addresses(11)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"2";
    regs_addresses(12)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"3";
    regs_addresses(13)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"6";
    regs_addresses(14)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "10" & x"7";
    regs_addresses(15)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "11" & x"0";
    regs_addresses(16)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "11" & x"1";
    regs_addresses(17)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "11" & x"2";
    regs_addresses(18)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "11" & x"3";
    regs_addresses(19)(REG_DRS_ADDRESS_MSB downto REG_DRS_ADDRESS_LSB) <= "11" & x"4";

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
    regs_read_arr(9)(REG_FPGA_DNA_DNA_LSBS_MSB downto REG_FPGA_DNA_DNA_LSBS_LSB) <= dna (31 downto 0);
    regs_read_arr(10)(REG_FPGA_DNA_DNA_MSBS_MSB downto REG_FPGA_DNA_DNA_MSBS_LSB) <= dna (56 downto 32);
    regs_read_arr(11)(REG_FPGA_RELEASE_DATE_MSB downto REG_FPGA_RELEASE_DATE_LSB) <= (RELEASE_YEAR & RELEASE_MONTH & RELEASE_DAY);
    regs_read_arr(12)(REG_FPGA_RELEASE_VERSION_MAJOR_MSB downto REG_FPGA_RELEASE_VERSION_MAJOR_LSB) <= (MAJOR_VERSION);
    regs_read_arr(12)(REG_FPGA_RELEASE_VERSION_MINOR_MSB downto REG_FPGA_RELEASE_VERSION_MINOR_LSB) <= (MINOR_VERSION);
    regs_read_arr(12)(REG_FPGA_RELEASE_VERSION_BUILD_MSB downto REG_FPGA_RELEASE_VERSION_BUILD_LSB) <= (RELEASE_VERSION);
    regs_read_arr(13)(REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_LSBS_MSB downto REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_LSBS_LSB) <= std_logic_vector(timestamp (31 downto 0));
    regs_read_arr(14)(REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_MSBS_MSB downto REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_MSBS_LSB) <= std_logic_vector(timestamp (47 downto 32));
    regs_read_arr(15)(REG_COUNTERS_CNT_SEM_CORRECTION_MSB downto REG_COUNTERS_CNT_SEM_CORRECTION_LSB) <= cnt_sem_corrected;
    regs_read_arr(16)(REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB downto REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB) <= cnt_sem_uncorrectable;
    regs_read_arr(17)(REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB downto REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB) <= cnt_readouts;
    regs_read_arr(18)(REG_COUNTERS_CNT_LOST_EVENT_MSB downto REG_COUNTERS_CNT_LOST_EVENT_LSB) <= cnt_lost_events;
    regs_read_arr(19)(REG_COUNTERS_CNT_EVENT_MSB downto REG_COUNTERS_CNT_EVENT_LSB) <= event_counter;

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

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    COUNTER_COUNTERS_CNT_SEM_CORRECTION : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        clk_i   => clock,
        rst_i   => ipb_reset,
        en_i    => sem_correction,
        snap_i  => '1',
        count_o => cnt_sem_corrected
    );


    COUNTER_COUNTERS_CNT_SEM_UNCORRECTABLE : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 4
    )
    port map (
        clk_i   => clock,
        rst_i   => ipb_reset,
        en_i    => sem_uncorrectable_error,
        snap_i  => '1',
        count_o => cnt_sem_uncorrectable
    );


    COUNTER_COUNTERS_CNT_READOUTS_COMPLETED : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        clk_i   => clock,
        rst_i   => ipb_reset,
        en_i    => readout_complete,
        snap_i  => '1',
        count_o => cnt_readouts
    );


    COUNTER_COUNTERS_CNT_LOST_EVENT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 16
    )
    port map (
        clk_i   => clock,
        rst_i   => ipb_reset,
        en_i    => trigger and busy,
        snap_i  => '1',
        count_o => cnt_lost_events
    );


    COUNTER_COUNTERS_CNT_EVENT : entity work.counter_snap
    generic map (
        g_COUNTER_WIDTH  => 32
    )
    port map (
        clk_i   => clock,
        rst_i   => ipb_reset,
        en_i    => trigger,
        snap_i  => '1',
        count_o => event_counter
    );


    -- Connect rate instances

    -- Connect read ready signals

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

    -- Create a sump for unused write signals
    sump_loop : for I in 0 to (REG_DRS_NUM_REGS-1) generate
    begin
    regs_write_arr_sump (I) <= or_reduce (regs_write_arr(I));
    end generate;
    --==== Registers end ============================================================================

end Behavioral;

