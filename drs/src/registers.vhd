library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> DRS Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_DRS_NUM_REGS : integer := 39;
    constant REG_DRS_ADDRESS_MSB : integer := 6;
    constant REG_DRS_ADDRESS_LSB : integer := 0;
    constant REG_CHIP_DMODE_ADDR    : std_logic_vector(6 downto 0) := "000" & x"0";
    constant REG_CHIP_DMODE_BIT    : integer := 1;
    constant REG_CHIP_DMODE_DEFAULT : std_logic := '1';

    constant REG_CHIP_STANDBY_MODE_ADDR    : std_logic_vector(6 downto 0) := "000" & x"0";
    constant REG_CHIP_STANDBY_MODE_BIT    : integer := 2;
    constant REG_CHIP_STANDBY_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_TRANSPARENT_MODE_ADDR    : std_logic_vector(6 downto 0) := "000" & x"0";
    constant REG_CHIP_TRANSPARENT_MODE_BIT    : integer := 3;
    constant REG_CHIP_TRANSPARENT_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_DRS_PLL_LOCK_ADDR    : std_logic_vector(6 downto 0) := "000" & x"0";
    constant REG_CHIP_DRS_PLL_LOCK_BIT    : integer := 4;

    constant REG_CHIP_CHANNEL_CONFIG_ADDR    : std_logic_vector(6 downto 0) := "000" & x"0";
    constant REG_CHIP_CHANNEL_CONFIG_MSB    : integer := 31;
    constant REG_CHIP_CHANNEL_CONFIG_LSB     : integer := 24;
    constant REG_CHIP_CHANNEL_CONFIG_DEFAULT : std_logic_vector(31 downto 24) := x"ff";

    constant REG_CHIP_DTAP_FREQ_ADDR    : std_logic_vector(6 downto 0) := "000" & x"1";
    constant REG_CHIP_DTAP_FREQ_MSB    : integer := 31;
    constant REG_CHIP_DTAP_FREQ_LSB     : integer := 0;

    constant REG_READOUT_ROI_MODE_ADDR    : std_logic_vector(6 downto 0) := "001" & x"0";
    constant REG_READOUT_ROI_MODE_BIT    : integer := 0;
    constant REG_READOUT_ROI_MODE_DEFAULT : std_logic := '1';

    constant REG_READOUT_BUSY_ADDR    : std_logic_vector(6 downto 0) := "001" & x"0";
    constant REG_READOUT_BUSY_BIT    : integer := 1;

    constant REG_READOUT_ADC_LATENCY_ADDR    : std_logic_vector(6 downto 0) := "001" & x"0";
    constant REG_READOUT_ADC_LATENCY_MSB    : integer := 9;
    constant REG_READOUT_ADC_LATENCY_LSB     : integer := 4;
    constant REG_READOUT_ADC_LATENCY_DEFAULT : std_logic_vector(9 downto 4) := "00" & x"0";

    constant REG_READOUT_SAMPLE_COUNT_ADDR    : std_logic_vector(6 downto 0) := "001" & x"0";
    constant REG_READOUT_SAMPLE_COUNT_MSB    : integer := 21;
    constant REG_READOUT_SAMPLE_COUNT_LSB     : integer := 12;
    constant REG_READOUT_SAMPLE_COUNT_DEFAULT : std_logic_vector(21 downto 12) := "11" & x"ff";

    constant REG_READOUT_EN_SPIKE_REMOVAL_ADDR    : std_logic_vector(6 downto 0) := "001" & x"0";
    constant REG_READOUT_EN_SPIKE_REMOVAL_BIT    : integer := 22;
    constant REG_READOUT_EN_SPIKE_REMOVAL_DEFAULT : std_logic := '1';

    constant REG_READOUT_READOUT_MASK_ADDR    : std_logic_vector(6 downto 0) := "001" & x"1";
    constant REG_READOUT_READOUT_MASK_MSB    : integer := 8;
    constant REG_READOUT_READOUT_MASK_LSB     : integer := 0;
    constant REG_READOUT_READOUT_MASK_DEFAULT : std_logic_vector(8 downto 0) := '1' & x"ff";

    constant REG_READOUT_AUTO_9TH_CHANNEL_ADDR    : std_logic_vector(6 downto 0) := "001" & x"1";
    constant REG_READOUT_AUTO_9TH_CHANNEL_BIT    : integer := 9;
    constant REG_READOUT_AUTO_9TH_CHANNEL_DEFAULT : std_logic := '1';

    constant REG_READOUT_START_ADDR    : std_logic_vector(6 downto 0) := "001" & x"2";
    constant REG_READOUT_START_BIT    : integer := 0;

    constant REG_READOUT_REINIT_ADDR    : std_logic_vector(6 downto 0) := "001" & x"3";
    constant REG_READOUT_REINIT_BIT    : integer := 0;

    constant REG_READOUT_CONFIGURE_ADDR    : std_logic_vector(6 downto 0) := "001" & x"4";
    constant REG_READOUT_CONFIGURE_BIT    : integer := 0;

    constant REG_READOUT_DRS_RESET_ADDR    : std_logic_vector(6 downto 0) := "001" & x"5";
    constant REG_READOUT_DRS_RESET_BIT    : integer := 0;

    constant REG_READOUT_DAQ_RESET_ADDR    : std_logic_vector(6 downto 0) := "001" & x"6";
    constant REG_READOUT_DAQ_RESET_BIT    : integer := 0;

    constant REG_READOUT_DMA_RESET_ADDR    : std_logic_vector(6 downto 0) := "001" & x"7";
    constant REG_READOUT_DMA_RESET_BIT    : integer := 0;

    constant REG_READOUT_WAIT_VDD_CLKS_ADDR    : std_logic_vector(6 downto 0) := "001" & x"8";
    constant REG_READOUT_WAIT_VDD_CLKS_MSB    : integer := 15;
    constant REG_READOUT_WAIT_VDD_CLKS_LSB     : integer := 0;
    constant REG_READOUT_WAIT_VDD_CLKS_DEFAULT : std_logic_vector(15 downto 0) := x"4000";

    constant REG_FPGA_DNA_DNA_LSBS_ADDR    : std_logic_vector(6 downto 0) := "010" & x"0";
    constant REG_FPGA_DNA_DNA_LSBS_MSB    : integer := 31;
    constant REG_FPGA_DNA_DNA_LSBS_LSB     : integer := 0;

    constant REG_FPGA_DNA_DNA_MSBS_ADDR    : std_logic_vector(6 downto 0) := "010" & x"1";
    constant REG_FPGA_DNA_DNA_MSBS_MSB    : integer := 24;
    constant REG_FPGA_DNA_DNA_MSBS_LSB     : integer := 0;

    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_ADDR    : std_logic_vector(6 downto 0) := "010" & x"4";
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_MSB    : integer := 31;
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_LSBS_LSB     : integer := 0;

    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_ADDR    : std_logic_vector(6 downto 0) := "010" & x"5";
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_MSB    : integer := 15;
    constant REG_FPGA_TIMESTAMP_TIMESTAMP_MSBS_LSB     : integer := 0;

    constant REG_FPGA_XADC_CALIBRATION_ADDR    : std_logic_vector(6 downto 0) := "010" & x"6";
    constant REG_FPGA_XADC_CALIBRATION_MSB    : integer := 11;
    constant REG_FPGA_XADC_CALIBRATION_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCPINT_ADDR    : std_logic_vector(6 downto 0) := "010" & x"6";
    constant REG_FPGA_XADC_VCCPINT_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCPINT_LSB     : integer := 16;

    constant REG_FPGA_XADC_VCCPAUX_ADDR    : std_logic_vector(6 downto 0) := "010" & x"7";
    constant REG_FPGA_XADC_VCCPAUX_MSB    : integer := 11;
    constant REG_FPGA_XADC_VCCPAUX_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCODDR_ADDR    : std_logic_vector(6 downto 0) := "010" & x"7";
    constant REG_FPGA_XADC_VCCODDR_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCODDR_LSB     : integer := 16;

    constant REG_FPGA_XADC_TEMP_ADDR    : std_logic_vector(6 downto 0) := "010" & x"8";
    constant REG_FPGA_XADC_TEMP_MSB    : integer := 11;
    constant REG_FPGA_XADC_TEMP_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCINT_ADDR    : std_logic_vector(6 downto 0) := "010" & x"8";
    constant REG_FPGA_XADC_VCCINT_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCINT_LSB     : integer := 16;

    constant REG_FPGA_XADC_VCCAUX_ADDR    : std_logic_vector(6 downto 0) := "010" & x"9";
    constant REG_FPGA_XADC_VCCAUX_MSB    : integer := 11;
    constant REG_FPGA_XADC_VCCAUX_LSB     : integer := 0;

    constant REG_FPGA_XADC_VCCBRAM_ADDR    : std_logic_vector(6 downto 0) := "010" & x"9";
    constant REG_FPGA_XADC_VCCBRAM_MSB    : integer := 27;
    constant REG_FPGA_XADC_VCCBRAM_LSB     : integer := 16;

    constant REG_DAQ_INJECT_DEBUG_PACKET_ADDR    : std_logic_vector(6 downto 0) := "011" & x"0";
    constant REG_DAQ_INJECT_DEBUG_PACKET_BIT    : integer := 0;

    constant REG_TRIGGER_FORCE_TRIGGER_ADDR    : std_logic_vector(6 downto 0) := "100" & x"0";
    constant REG_TRIGGER_FORCE_TRIGGER_BIT    : integer := 0;

    constant REG_TRIGGER_EXT_TRIGGER_EN_ADDR    : std_logic_vector(6 downto 0) := "100" & x"1";
    constant REG_TRIGGER_EXT_TRIGGER_EN_BIT    : integer := 0;
    constant REG_TRIGGER_EXT_TRIGGER_EN_DEFAULT : std_logic := '1';

    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_ADDR    : std_logic_vector(6 downto 0) := "100" & x"1";
    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_BIT    : integer := 1;
    constant REG_TRIGGER_EXT_TRIGGER_ACTIVE_HI_DEFAULT : std_logic := '1';

    constant REG_COUNTERS_CNT_SEM_CORRECTION_ADDR    : std_logic_vector(6 downto 0) := "101" & x"0";
    constant REG_COUNTERS_CNT_SEM_CORRECTION_MSB    : integer := 15;
    constant REG_COUNTERS_CNT_SEM_CORRECTION_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_ADDR    : std_logic_vector(6 downto 0) := "101" & x"1";
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB    : integer := 19;
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_ADDR    : std_logic_vector(6 downto 0) := "101" & x"2";
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_ADDR    : std_logic_vector(6 downto 0) := "101" & x"3";
    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_DMA_READOUTS_COMPLETED_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_LOST_EVENT_ADDR    : std_logic_vector(6 downto 0) := "101" & x"4";
    constant REG_COUNTERS_CNT_LOST_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_LOST_EVENT_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_EVENT_ADDR    : std_logic_vector(6 downto 0) := "101" & x"5";
    constant REG_COUNTERS_CNT_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_EVENT_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_DATE_ADDR    : std_logic_vector(6 downto 0) := "110" & x"0";
    constant REG_HOG_GLOBAL_DATE_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_DATE_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_TIME_ADDR    : std_logic_vector(6 downto 0) := "110" & x"1";
    constant REG_HOG_GLOBAL_TIME_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_TIME_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_VER_ADDR    : std_logic_vector(6 downto 0) := "110" & x"2";
    constant REG_HOG_GLOBAL_VER_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_VER_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_SHA_ADDR    : std_logic_vector(6 downto 0) := "110" & x"3";
    constant REG_HOG_GLOBAL_SHA_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_SHA_ADDR    : std_logic_vector(6 downto 0) := "110" & x"4";
    constant REG_HOG_TOP_SHA_MSB    : integer := 31;
    constant REG_HOG_TOP_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_VER_ADDR    : std_logic_vector(6 downto 0) := "110" & x"5";
    constant REG_HOG_TOP_VER_MSB    : integer := 31;
    constant REG_HOG_TOP_VER_LSB     : integer := 0;

    constant REG_HOG_HOG_SHA_ADDR    : std_logic_vector(6 downto 0) := "110" & x"6";
    constant REG_HOG_HOG_SHA_MSB    : integer := 31;
    constant REG_HOG_HOG_SHA_LSB     : integer := 0;

    constant REG_HOG_HOG_VER_ADDR    : std_logic_vector(6 downto 0) := "110" & x"7";
    constant REG_HOG_HOG_VER_MSB    : integer := 31;
    constant REG_HOG_HOG_VER_LSB     : integer := 0;

    constant REG_SPY_RESET_ADDR    : std_logic_vector(6 downto 0) := "111" & x"0";
    constant REG_SPY_RESET_BIT    : integer := 0;

    constant REG_SPY_DATA_ADDR    : std_logic_vector(6 downto 0) := "111" & x"1";
    constant REG_SPY_DATA_MSB    : integer := 15;
    constant REG_SPY_DATA_LSB     : integer := 0;

    constant REG_SPY_FULL_ADDR    : std_logic_vector(6 downto 0) := "111" & x"2";
    constant REG_SPY_FULL_BIT    : integer := 0;

    constant REG_SPY_EMPTY_ADDR    : std_logic_vector(6 downto 0) := "111" & x"2";
    constant REG_SPY_EMPTY_BIT    : integer := 1;


end registers;
