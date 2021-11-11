library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> MT Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_MT_NUM_REGS : integer := 68;
    constant REG_MT_ADDRESS_MSB : integer := 8;
    constant REG_MT_ADDRESS_LSB : integer := 0;
    constant REG_MT_HIT_COUNTERS_RB0_ADDR    : std_logic_vector(8 downto 0) := '0' & x"10";
    constant REG_MT_HIT_COUNTERS_RB0_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB0_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB1_ADDR    : std_logic_vector(8 downto 0) := '0' & x"11";
    constant REG_MT_HIT_COUNTERS_RB1_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB1_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB2_ADDR    : std_logic_vector(8 downto 0) := '0' & x"12";
    constant REG_MT_HIT_COUNTERS_RB2_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB2_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB3_ADDR    : std_logic_vector(8 downto 0) := '0' & x"13";
    constant REG_MT_HIT_COUNTERS_RB3_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB3_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB4_ADDR    : std_logic_vector(8 downto 0) := '0' & x"14";
    constant REG_MT_HIT_COUNTERS_RB4_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB4_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB5_ADDR    : std_logic_vector(8 downto 0) := '0' & x"15";
    constant REG_MT_HIT_COUNTERS_RB5_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB5_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB6_ADDR    : std_logic_vector(8 downto 0) := '0' & x"16";
    constant REG_MT_HIT_COUNTERS_RB6_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB6_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB7_ADDR    : std_logic_vector(8 downto 0) := '0' & x"17";
    constant REG_MT_HIT_COUNTERS_RB7_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB7_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB8_ADDR    : std_logic_vector(8 downto 0) := '0' & x"18";
    constant REG_MT_HIT_COUNTERS_RB8_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB8_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB9_ADDR    : std_logic_vector(8 downto 0) := '0' & x"19";
    constant REG_MT_HIT_COUNTERS_RB9_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB9_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB10_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1a";
    constant REG_MT_HIT_COUNTERS_RB10_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB10_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB11_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1b";
    constant REG_MT_HIT_COUNTERS_RB11_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB11_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB12_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1c";
    constant REG_MT_HIT_COUNTERS_RB12_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB12_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB13_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1d";
    constant REG_MT_HIT_COUNTERS_RB13_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB13_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB14_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1e";
    constant REG_MT_HIT_COUNTERS_RB14_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB14_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB15_ADDR    : std_logic_vector(8 downto 0) := '0' & x"1f";
    constant REG_MT_HIT_COUNTERS_RB15_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB15_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB16_ADDR    : std_logic_vector(8 downto 0) := '0' & x"20";
    constant REG_MT_HIT_COUNTERS_RB16_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB16_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB17_ADDR    : std_logic_vector(8 downto 0) := '0' & x"21";
    constant REG_MT_HIT_COUNTERS_RB17_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB17_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB18_ADDR    : std_logic_vector(8 downto 0) := '0' & x"22";
    constant REG_MT_HIT_COUNTERS_RB18_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB18_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB19_ADDR    : std_logic_vector(8 downto 0) := '0' & x"23";
    constant REG_MT_HIT_COUNTERS_RB19_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB19_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB20_ADDR    : std_logic_vector(8 downto 0) := '0' & x"24";
    constant REG_MT_HIT_COUNTERS_RB20_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB20_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB21_ADDR    : std_logic_vector(8 downto 0) := '0' & x"25";
    constant REG_MT_HIT_COUNTERS_RB21_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB21_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB22_ADDR    : std_logic_vector(8 downto 0) := '0' & x"26";
    constant REG_MT_HIT_COUNTERS_RB22_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB22_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB23_ADDR    : std_logic_vector(8 downto 0) := '0' & x"27";
    constant REG_MT_HIT_COUNTERS_RB23_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB23_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB24_ADDR    : std_logic_vector(8 downto 0) := '0' & x"28";
    constant REG_MT_HIT_COUNTERS_RB24_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB24_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB25_ADDR    : std_logic_vector(8 downto 0) := '0' & x"29";
    constant REG_MT_HIT_COUNTERS_RB25_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB25_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB26_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2a";
    constant REG_MT_HIT_COUNTERS_RB26_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB26_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB27_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2b";
    constant REG_MT_HIT_COUNTERS_RB27_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB27_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB28_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2c";
    constant REG_MT_HIT_COUNTERS_RB28_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB28_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB29_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2d";
    constant REG_MT_HIT_COUNTERS_RB29_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB29_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB30_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2e";
    constant REG_MT_HIT_COUNTERS_RB30_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB30_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB31_ADDR    : std_logic_vector(8 downto 0) := '0' & x"2f";
    constant REG_MT_HIT_COUNTERS_RB31_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB31_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB32_ADDR    : std_logic_vector(8 downto 0) := '0' & x"30";
    constant REG_MT_HIT_COUNTERS_RB32_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB32_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB33_ADDR    : std_logic_vector(8 downto 0) := '0' & x"31";
    constant REG_MT_HIT_COUNTERS_RB33_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB33_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB34_ADDR    : std_logic_vector(8 downto 0) := '0' & x"32";
    constant REG_MT_HIT_COUNTERS_RB34_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB34_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB35_ADDR    : std_logic_vector(8 downto 0) := '0' & x"33";
    constant REG_MT_HIT_COUNTERS_RB35_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB35_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB36_ADDR    : std_logic_vector(8 downto 0) := '0' & x"34";
    constant REG_MT_HIT_COUNTERS_RB36_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB36_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB37_ADDR    : std_logic_vector(8 downto 0) := '0' & x"35";
    constant REG_MT_HIT_COUNTERS_RB37_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB37_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB38_ADDR    : std_logic_vector(8 downto 0) := '0' & x"36";
    constant REG_MT_HIT_COUNTERS_RB38_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB38_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB39_ADDR    : std_logic_vector(8 downto 0) := '0' & x"37";
    constant REG_MT_HIT_COUNTERS_RB39_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB39_LSB     : integer := 0;

    constant REG_MT_HIT_MASK_LT0_ADDR    : std_logic_vector(8 downto 0) := '0' & x"40";
    constant REG_MT_HIT_MASK_LT0_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT0_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT0_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT1_ADDR    : std_logic_vector(8 downto 0) := '0' & x"41";
    constant REG_MT_HIT_MASK_LT1_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT1_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT1_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT2_ADDR    : std_logic_vector(8 downto 0) := '0' & x"42";
    constant REG_MT_HIT_MASK_LT2_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT2_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT2_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT3_ADDR    : std_logic_vector(8 downto 0) := '0' & x"43";
    constant REG_MT_HIT_MASK_LT3_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT3_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT3_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT4_ADDR    : std_logic_vector(8 downto 0) := '0' & x"44";
    constant REG_MT_HIT_MASK_LT4_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT4_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT4_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT5_ADDR    : std_logic_vector(8 downto 0) := '0' & x"45";
    constant REG_MT_HIT_MASK_LT5_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT5_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT5_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT6_ADDR    : std_logic_vector(8 downto 0) := '0' & x"46";
    constant REG_MT_HIT_MASK_LT6_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT6_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT6_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT7_ADDR    : std_logic_vector(8 downto 0) := '0' & x"47";
    constant REG_MT_HIT_MASK_LT7_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT7_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT7_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT8_ADDR    : std_logic_vector(8 downto 0) := '0' & x"48";
    constant REG_MT_HIT_MASK_LT8_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT8_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT8_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT9_ADDR    : std_logic_vector(8 downto 0) := '0' & x"49";
    constant REG_MT_HIT_MASK_LT9_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT9_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT9_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT10_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4a";
    constant REG_MT_HIT_MASK_LT10_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT10_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT10_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT11_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4b";
    constant REG_MT_HIT_MASK_LT11_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT11_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT11_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT12_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4c";
    constant REG_MT_HIT_MASK_LT12_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT12_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT12_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT13_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4d";
    constant REG_MT_HIT_MASK_LT13_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT13_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT13_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT14_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4e";
    constant REG_MT_HIT_MASK_LT14_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT14_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT14_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT15_ADDR    : std_logic_vector(8 downto 0) := '0' & x"4f";
    constant REG_MT_HIT_MASK_LT15_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT15_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT15_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT16_ADDR    : std_logic_vector(8 downto 0) := '0' & x"50";
    constant REG_MT_HIT_MASK_LT16_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT16_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT16_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT17_ADDR    : std_logic_vector(8 downto 0) := '0' & x"51";
    constant REG_MT_HIT_MASK_LT17_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT17_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT17_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT18_ADDR    : std_logic_vector(8 downto 0) := '0' & x"52";
    constant REG_MT_HIT_MASK_LT18_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT18_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT18_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT19_ADDR    : std_logic_vector(8 downto 0) := '0' & x"53";
    constant REG_MT_HIT_MASK_LT19_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT19_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT19_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HOG_GLOBAL_DATE_ADDR    : std_logic_vector(8 downto 0) := '1' & x"00";
    constant REG_MT_HOG_GLOBAL_DATE_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_DATE_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_TIME_ADDR    : std_logic_vector(8 downto 0) := '1' & x"01";
    constant REG_MT_HOG_GLOBAL_TIME_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_TIME_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_VER_ADDR    : std_logic_vector(8 downto 0) := '1' & x"02";
    constant REG_MT_HOG_GLOBAL_VER_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_VER_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_SHA_ADDR    : std_logic_vector(8 downto 0) := '1' & x"03";
    constant REG_MT_HOG_GLOBAL_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_TOP_SHA_ADDR    : std_logic_vector(8 downto 0) := '1' & x"04";
    constant REG_MT_HOG_TOP_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_TOP_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_TOP_VER_ADDR    : std_logic_vector(8 downto 0) := '1' & x"05";
    constant REG_MT_HOG_TOP_VER_MSB    : integer := 31;
    constant REG_MT_HOG_TOP_VER_LSB     : integer := 0;

    constant REG_MT_HOG_HOG_SHA_ADDR    : std_logic_vector(8 downto 0) := '1' & x"06";
    constant REG_MT_HOG_HOG_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_HOG_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_HOG_VER_ADDR    : std_logic_vector(8 downto 0) := '1' & x"07";
    constant REG_MT_HOG_HOG_VER_MSB    : integer := 31;
    constant REG_MT_HOG_HOG_VER_LSB     : integer := 0;


end registers;
