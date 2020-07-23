library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> DRS Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_DRS_NUM_REGS : integer := 20;
    constant REG_DRS_ADDRESS_MSB : integer := 5;
    constant REG_DRS_ADDRESS_LSB : integer := 0;
    constant REG_CHIP_DMODE_ADDR    : std_logic_vector(5 downto 0) := "00" & x"0";
    constant REG_CHIP_DMODE_BIT    : integer := 1;
    constant REG_CHIP_DMODE_DEFAULT : std_logic := '1';

    constant REG_CHIP_STANDBY_MODE_ADDR    : std_logic_vector(5 downto 0) := "00" & x"0";
    constant REG_CHIP_STANDBY_MODE_BIT    : integer := 2;
    constant REG_CHIP_STANDBY_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_TRANSPARENT_MODE_ADDR    : std_logic_vector(5 downto 0) := "00" & x"0";
    constant REG_CHIP_TRANSPARENT_MODE_BIT    : integer := 3;
    constant REG_CHIP_TRANSPARENT_MODE_DEFAULT : std_logic := '0';

    constant REG_CHIP_DRS_PLL_LOCK_ADDR    : std_logic_vector(5 downto 0) := "00" & x"0";
    constant REG_CHIP_DRS_PLL_LOCK_BIT    : integer := 4;

    constant REG_CHIP_CHANNEL_CONFIG_ADDR    : std_logic_vector(5 downto 0) := "00" & x"0";
    constant REG_CHIP_CHANNEL_CONFIG_MSB    : integer := 31;
    constant REG_CHIP_CHANNEL_CONFIG_LSB     : integer := 24;
    constant REG_CHIP_CHANNEL_CONFIG_DEFAULT : std_logic_vector(31 downto 24) := x"ff";

    constant REG_CHIP_DTAP_HIGH_CNTS_ADDR    : std_logic_vector(5 downto 0) := "00" & x"1";
    constant REG_CHIP_DTAP_HIGH_CNTS_MSB    : integer := 24;
    constant REG_CHIP_DTAP_HIGH_CNTS_LSB     : integer := 0;

    constant REG_CHIP_DTAP_LOW_CNTS_ADDR    : std_logic_vector(5 downto 0) := "00" & x"2";
    constant REG_CHIP_DTAP_LOW_CNTS_MSB    : integer := 24;
    constant REG_CHIP_DTAP_LOW_CNTS_LSB     : integer := 0;

    constant REG_READOUT_ROI_MODE_ADDR    : std_logic_vector(5 downto 0) := "01" & x"0";
    constant REG_READOUT_ROI_MODE_BIT    : integer := 0;
    constant REG_READOUT_ROI_MODE_DEFAULT : std_logic := '1';

    constant REG_READOUT_BUSY_ADDR    : std_logic_vector(5 downto 0) := "01" & x"0";
    constant REG_READOUT_BUSY_BIT    : integer := 1;

    constant REG_READOUT_ADC_LATENCY_ADDR    : std_logic_vector(5 downto 0) := "01" & x"0";
    constant REG_READOUT_ADC_LATENCY_MSB    : integer := 9;
    constant REG_READOUT_ADC_LATENCY_LSB     : integer := 4;
    constant REG_READOUT_ADC_LATENCY_DEFAULT : std_logic_vector(9 downto 4) := "00" & x"0";

    constant REG_READOUT_SAMPLE_COUNT_ADDR    : std_logic_vector(5 downto 0) := "01" & x"0";
    constant REG_READOUT_SAMPLE_COUNT_MSB    : integer := 22;
    constant REG_READOUT_SAMPLE_COUNT_LSB     : integer := 12;
    constant REG_READOUT_SAMPLE_COUNT_DEFAULT : std_logic_vector(22 downto 12) := "100" & x"00";

    constant REG_READOUT_READOUT_MASK_ADDR    : std_logic_vector(5 downto 0) := "01" & x"1";
    constant REG_READOUT_READOUT_MASK_MSB    : integer := 8;
    constant REG_READOUT_READOUT_MASK_LSB     : integer := 0;
    constant REG_READOUT_READOUT_MASK_DEFAULT : std_logic_vector(8 downto 0) := '1' & x"ff";

    constant REG_READOUT_START_ADDR    : std_logic_vector(5 downto 0) := "01" & x"2";
    constant REG_READOUT_START_BIT    : integer := 0;

    constant REG_READOUT_REINIT_ADDR    : std_logic_vector(5 downto 0) := "01" & x"3";
    constant REG_READOUT_REINIT_BIT    : integer := 0;

    constant REG_READOUT_CONFIGURE_ADDR    : std_logic_vector(5 downto 0) := "01" & x"4";
    constant REG_READOUT_CONFIGURE_BIT    : integer := 0;

    constant REG_READOUT_RESET_ADDR    : std_logic_vector(5 downto 0) := "01" & x"5";
    constant REG_READOUT_RESET_BIT    : integer := 0;

    constant REG_FPGA_DNA_DNA_LSBS_ADDR    : std_logic_vector(5 downto 0) := "10" & x"0";
    constant REG_FPGA_DNA_DNA_LSBS_MSB    : integer := 31;
    constant REG_FPGA_DNA_DNA_LSBS_LSB     : integer := 0;

    constant REG_FPGA_DNA_DNA_MSBS_ADDR    : std_logic_vector(5 downto 0) := "10" & x"1";
    constant REG_FPGA_DNA_DNA_MSBS_MSB    : integer := 24;
    constant REG_FPGA_DNA_DNA_MSBS_LSB     : integer := 0;

    constant REG_FPGA_RELEASE_DATE_ADDR    : std_logic_vector(5 downto 0) := "10" & x"2";
    constant REG_FPGA_RELEASE_DATE_MSB    : integer := 31;
    constant REG_FPGA_RELEASE_DATE_LSB     : integer := 0;

    constant REG_FPGA_RELEASE_VERSION_MAJOR_ADDR    : std_logic_vector(5 downto 0) := "10" & x"3";
    constant REG_FPGA_RELEASE_VERSION_MAJOR_MSB    : integer := 7;
    constant REG_FPGA_RELEASE_VERSION_MAJOR_LSB     : integer := 0;

    constant REG_FPGA_RELEASE_VERSION_MINOR_ADDR    : std_logic_vector(5 downto 0) := "10" & x"3";
    constant REG_FPGA_RELEASE_VERSION_MINOR_MSB    : integer := 15;
    constant REG_FPGA_RELEASE_VERSION_MINOR_LSB     : integer := 8;

    constant REG_FPGA_RELEASE_VERSION_BUILD_ADDR    : std_logic_vector(5 downto 0) := "10" & x"3";
    constant REG_FPGA_RELEASE_VERSION_BUILD_MSB    : integer := 23;
    constant REG_FPGA_RELEASE_VERSION_BUILD_LSB     : integer := 16;

    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_LSBS_ADDR    : std_logic_vector(5 downto 0) := "10" & x"6";
    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_LSBS_MSB    : integer := 31;
    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_LSBS_LSB     : integer := 0;

    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_MSBS_ADDR    : std_logic_vector(5 downto 0) := "10" & x"7";
    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_MSBS_MSB    : integer := 15;
    constant REG_FPGA_RELEASE_TIMESTAMP_TIMESTAMP_MSBS_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_SEM_CORRECTION_ADDR    : std_logic_vector(5 downto 0) := "11" & x"0";
    constant REG_COUNTERS_CNT_SEM_CORRECTION_MSB    : integer := 15;
    constant REG_COUNTERS_CNT_SEM_CORRECTION_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_ADDR    : std_logic_vector(5 downto 0) := "11" & x"1";
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_MSB    : integer := 19;
    constant REG_COUNTERS_CNT_SEM_UNCORRECTABLE_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_ADDR    : std_logic_vector(5 downto 0) := "11" & x"2";
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_MSB    : integer := 15;
    constant REG_COUNTERS_CNT_READOUTS_COMPLETED_LSB     : integer := 0;

    constant REG_COUNTERS_CNT_LOST_EVENT_ADDR    : std_logic_vector(5 downto 0) := "11" & x"3";
    constant REG_COUNTERS_CNT_LOST_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_LOST_EVENT_LSB     : integer := 16;

    constant REG_COUNTERS_CNT_EVENT_ADDR    : std_logic_vector(5 downto 0) := "11" & x"4";
    constant REG_COUNTERS_CNT_EVENT_MSB    : integer := 31;
    constant REG_COUNTERS_CNT_EVENT_LSB     : integer := 0;


end registers;
