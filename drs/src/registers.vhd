library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> DRS Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_DRS_NUM_REGS : integer := 49;
    constant REG_DRS_ADDRESS_MSB : integer := 9;
    constant REG_DRS_ADDRESS_LSB : integer := 0;
    constant REG_CHIP_DMODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_CHIP_DMODE_BIT    : integer := 1;
    constant REG_CHIP_DMODE_DEFAULT : std_logic := '1';

    constant REG_CHIP_STANDBY_MODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_CHIP_STANDBY_MODE_BIT    : integer := 2;
    constant REG_CHIP_STANDBY_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_TRANSPARENT_MODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_CHIP_TRANSPARENT_MODE_BIT    : integer := 3;
    constant REG_CHIP_TRANSPARENT_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_DRS_PLL_LOCK_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_CHIP_DRS_PLL_LOCK_BIT    : integer := 4;

    constant REG_CHIP_CHANNEL_CONFIG_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_CHIP_CHANNEL_CONFIG_MSB    : integer := 31;
    constant REG_CHIP_CHANNEL_CONFIG_LSB     : integer := 24;
    constant REG_CHIP_CHANNEL_CONFIG_DEFAULT : std_logic_vector(31 downto 24) := x"ff";

    constant REG_CHIP_DTAP_FREQ_ADDR    : std_logic_vector(9 downto 0) := "00" & x"01";
    constant REG_CHIP_DTAP_FREQ_MSB    : integer := 15;
    constant REG_CHIP_DTAP_FREQ_LSB     : integer := 0;

    constant REG_READOUT_ROI_MODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_READOUT_ROI_MODE_BIT    : integer := 0;
    constant REG_READOUT_ROI_MODE_DEFAULT : std_logic := '1';

    constant REG_READOUT_BUSY_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_READOUT_BUSY_BIT    : integer := 1;

    constant REG_READOUT_ADC_LATENCY_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_READOUT_ADC_LATENCY_MSB    : integer := 9;
    constant REG_READOUT_ADC_LATENCY_LSB     : integer := 4;
    constant REG_READOUT_ADC_LATENCY_DEFAULT : std_logic_vector(9 downto 4) := "00" & x"9";

    constant REG_READOUT_SAMPLE_COUNT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_READOUT_SAMPLE_COUNT_MSB    : integer := 21;
    constant REG_READOUT_SAMPLE_COUNT_LSB     : integer := 12;
    constant REG_READOUT_SAMPLE_COUNT_DEFAULT : std_logic_vector(21 downto 12) := "11" & x"ff";

    constant REG_READOUT_EN_SPIKE_REMOVAL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_READOUT_EN_SPIKE_REMOVAL_BIT    : integer := 22;
    constant REG_READOUT_EN_SPIKE_REMOVAL_DEFAULT : std_logic := '1';

    constant REG_READOUT_READOUT_MASK_ADDR    : std_logic_vector(9 downto 0) := "00" & x"11";
    constant REG_READOUT_READOUT_MASK_MSB    : integer := 8;
    constant REG_READOUT_READOUT_MASK_LSB     : integer := 0;
    constant REG_READOUT_READOUT_MASK_DEFAULT : std_logic_vector(8 downto 0) := '1' & x"ff";

    constant REG_READOUT_AUTO_9TH_CHANNEL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"11";
    constant REG_READOUT_AUTO_9TH_CHANNEL_BIT    : integer := 9;
    constant REG_READOUT_AUTO_9TH_CHANNEL_DEFAULT : std_logic := '1';

    constant REG_READOUT_START_ADDR    : std_logic_vector(9 downto 0) := "00" & x"12";
    constant REG_READOUT_START_BIT    : integer := 0;

    constant REG_READOUT_REINIT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"13";
    constant REG_READOUT_REINIT_BIT    : integer := 0;

    constant REG_READOUT_CONFIGURE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_READOUT_CONFIGURE_BIT    : integer := 0;

    constant REG_READOUT_DRS_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"15";
    constant REG_READOUT_DRS_RESET_BIT    : integer := 0;

    constant REG_READOUT_DAQ_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"16";
    constant REG_READOUT_DAQ_RESET_BIT    : integer := 0;

    constant REG_READOUT_DMA_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"17";
    constant REG_READOUT_DMA_RESET_BIT    : integer := 0;

    constant REG_READOUT_WAIT_VDD_CLKS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"18";
    constant REG_READOUT_WAIT_VDD_CLKS_MSB    : integer := 15;
    constant REG_READOUT_WAIT_VDD_CLKS_LSB     : integer := 0;
    constant REG_READOUT_WAIT_VDD_CLKS_DEFAULT : std_logic_vector(15 downto 0) := x"014d";

    constant REG_READOUT_DRS_DIAGNOSTIC_MODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"19";
    constant REG_READOUT_DRS_DIAGNOSTIC_MODE_BIT    : integer := 0;
    constant REG_READOUT_DRS_DIAGNOSTIC_MODE_DEFAULT : std_logic := '0';

    constant REG_FPGA_DNA_DNA_LSBS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"20";
    constant REG_FPGA_DNA_DNA_LSBS_MSB    : integer := 31;
    constant REG_FPGA_DNA_DNA_LSBS_LSB     : integer := 0;

    constant REG_FPGA_DNA_DNA_MSBS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"21";
    constant REG_FPGA_DNA_DNA_MSBS_MSB    : integer := 24;
    constant REG_FPGA_DNA_DNA_MSBS_LSB     : integer := 0;

    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"24";
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_MSB    : integer := 31;
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_LSB     : integer := 0;

    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"25";
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_MSB    : integer := 15;
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_LSB     : integer := 0;

    constant REG_FPGA_XADC_CALIBRATION_ADDR    : std_logic_vector(9 downto 0) := "00" & x"26";
    constant REG_FPGA_XADC_CALIBRATION_MSB    : integer := 11;
    constant REG_FPGA_XADC_CALIBRATION_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCPINT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"26";
    constant REG_FPGA_XADC_VCCPINT_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCPINT_LSB     : integer := 16;

    constant REG_FPGA_XADC_VCCPAUX_ADDR    : std_logic_vector(9 downto 0) := "00" & x"27";
    constant REG_FPGA_XADC_VCCPAUX_MSB    : integer := 11;
    constant REG_FPGA_XADC_VCCPAUX_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCODDR_ADDR    : std_logic_vector(9 downto 0) := "00" & x"27";
    constant REG_FPGA_XADC_VCCODDR_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCODDR_LSB     : integer := 16;

    constant REG_FPGA_XADC_TEMP_ADDR    : std_logic_vector(9 downto 0) := "00" & x"28";
    constant REG_FPGA_XADC_TEMP_MSB    : integer := 11;
    constant REG_FPGA_XADC_TEMP_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCINT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"28";
    constant REG_FPGA_XADC_VCCINT_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCINT_LSB     : integer := 16;

    constant REG_FPGA_XADC_VCCAUX_ADDR    : std_logic_vector(9 downto 0) := "00" & x"29";
    constant REG_FPGA_XADC_VCCAUX_MSB    : integer := 11;
    constant REG_FPGA_XADC_VCCAUX_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCBRAM_ADDR    : std_logic_vector(9 downto 0) := "00" & x"29";
    constant REG_FPGA_XADC_VCCBRAM_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCBRAM_LSB     : integer := 16;

    constant REG_FPGA_BOARD_ID_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2a";
    constant REG_FPGA_BOARD_ID_MSB    : integer := 7;
    constant REG_FPGA_BOARD_ID_LSB     : integer := 0;
    constant REG_FPGA_BOARD_ID_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_DAQ_INJECT_DEBUG_PACKET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"30";
    constant REG_DAQ_INJECT_DEBUG_PACKET_BIT    : integer := 0;

    constant REG_TRIGGER_FORCE_TRIGGER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"40";
    constant REG_TRIGGER_FORCE_TRIGGER_BIT    : integer := 0;

    constant REG_TRIGGER_EXT_TRIGGER_EN_ADDR    : std_logic_vector(9 downto 0) := "00" & x"41";
    constant REG_TRIGGER_EXT_TRIGGER_EN_BIT    : integer := 0;
    constant REG_TRIGGER_EXT_TRIGGER_EN_DEFAULT : std_logic := '1';

    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_ADDR    : std_logic_vector(9 downto 0) := "00" & x"41";
    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT    : integer := 1;
    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_DEFAULT : std_logic := '1';

    constant REG_COUNTERS_CNT_SEM_CORRECTION_ADDR    : std_logic_vector(9 downto 0) := "00" & x"50";
    constant REG_COUNTERS_CNT_SEM_CORRECTION_MSB    : integer := 15;
    constant REG_COUNTERS_CNT_SEM_CORRECTION_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"51";
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB    : integer := 19;
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_ADDR    : std_logic_vector(9 downto 0) := "00" & x"52";
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_ADDR    : std_logic_vector(9 downto 0) := "00" & x"53";
    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_LOST_EVENT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"54";
    constant REG_COUNTERS_CNT_LOST_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_LOST_EVENT_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_EVENT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"55";
    constant REG_COUNTERS_CNT_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_EVENT_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_DATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"60";
    constant REG_HOG_GLOBAL_DATE_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_DATE_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_TIME_ADDR    : std_logic_vector(9 downto 0) := "00" & x"61";
    constant REG_HOG_GLOBAL_TIME_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_TIME_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_VER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"62";
    constant REG_HOG_GLOBAL_VER_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_VER_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_SHA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"63";
    constant REG_HOG_GLOBAL_SHA_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_SHA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"64";
    constant REG_HOG_TOP_SHA_MSB    : integer := 31;
    constant REG_HOG_TOP_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_VER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"65";
    constant REG_HOG_TOP_VER_MSB    : integer := 31;
    constant REG_HOG_TOP_VER_LSB     : integer := 0;

    constant REG_HOG_HOG_SHA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"66";
    constant REG_HOG_HOG_SHA_MSB    : integer := 31;
    constant REG_HOG_HOG_SHA_LSB     : integer := 0;

    constant REG_HOG_HOG_VER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"67";
    constant REG_HOG_HOG_VER_MSB    : integer := 31;
    constant REG_HOG_HOG_VER_LSB     : integer := 0;

    constant REG_SPY_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"70";
    constant REG_SPY_RESET_BIT    : integer := 0;

    constant REG_SPY_DATA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"71";
    constant REG_SPY_DATA_MSB    : integer := 15;
    constant REG_SPY_DATA_LSB     : integer := 0;

    constant REG_SPY_FULL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"72";
    constant REG_SPY_FULL_BIT    : integer := 0;

    constant REG_SPY_EMPTY_ADDR    : std_logic_vector(9 downto 0) := "00" & x"72";
    constant REG_SPY_EMPTY_BIT    : integer := 1;

    constant REG_DMA_RAM_A_OCC_RST_ADDR    : std_logic_vector(9 downto 0) := "01" & x"00";
    constant REG_DMA_RAM_A_OCC_RST_BIT    : integer := 0;

    constant REG_DMA_RAM_B_OCC_RST_ADDR    : std_logic_vector(9 downto 0) := "01" & x"01";
    constant REG_DMA_RAM_B_OCC_RST_BIT    : integer := 0;

    constant REG_DMA_RAM_A_OCCUPANCY_ADDR    : std_logic_vector(9 downto 0) := "01" & x"02";
    constant REG_DMA_RAM_A_OCCUPANCY_MSB    : integer := 31;
    constant REG_DMA_RAM_A_OCCUPANCY_LSB     : integer := 0;

    constant REG_DMA_RAM_B_OCCUPANCY_ADDR    : std_logic_vector(9 downto 0) := "01" & x"03";
    constant REG_DMA_RAM_B_OCCUPANCY_MSB    : integer := 31;
    constant REG_DMA_RAM_B_OCCUPANCY_LSB     : integer := 0;

    constant REG_DMA_DMA_POINTER_ADDR    : std_logic_vector(9 downto 0) := "01" & x"04";
    constant REG_DMA_DMA_POINTER_MSB    : integer := 31;
    constant REG_DMA_DMA_POINTER_LSB     : integer := 0;

    constant REG_DMA_TOGGLE_RAM_ADDR    : std_logic_vector(9 downto 0) := "01" & x"05";
    constant REG_DMA_TOGGLE_RAM_BIT    : integer := 0;

    constant REG_GFP_EVENTID_SPI_EN_ADDR    : std_logic_vector(9 downto 0) := "10" & x"00";
    constant REG_GFP_EVENTID_SPI_EN_BIT    : integer := 0;
    constant REG_GFP_EVENTID_SPI_EN_DEFAULT : std_logic := '0';

    constant REG_GFP_EVENTID_RX_ADDR    : std_logic_vector(9 downto 0) := "10" & x"01";
    constant REG_GFP_EVENTID_RX_MSB    : integer := 31;
    constant REG_GFP_EVENTID_RX_LSB     : integer := 0;


end registers;
