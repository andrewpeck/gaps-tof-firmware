library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> MT Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_MT_NUM_REGS : integer := 143;
    constant REG_MT_ADDRESS_MSB : integer := 9;
    constant REG_MT_ADDRESS_LSB : integer := 0;
    constant REG_MT_LOOPBACK_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_MT_LOOPBACK_MSB    : integer := 31;
    constant REG_MT_LOOPBACK_LSB     : integer := 0;
    constant REG_MT_LOOPBACK_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_MT_CLOCK_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"01";
    constant REG_MT_CLOCK_RATE_MSB    : integer := 31;
    constant REG_MT_CLOCK_RATE_LSB     : integer := 0;

    constant REG_MT_FB_CLOCK_RATE_0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"02";
    constant REG_MT_FB_CLOCK_RATE_0_MSB    : integer := 31;
    constant REG_MT_FB_CLOCK_RATE_0_LSB     : integer := 0;

    constant REG_MT_FB_CLOCK_RATE_1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"03";
    constant REG_MT_FB_CLOCK_RATE_1_MSB    : integer := 31;
    constant REG_MT_FB_CLOCK_RATE_1_LSB     : integer := 0;

    constant REG_MT_FB_CLOCK_RATE_2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"04";
    constant REG_MT_FB_CLOCK_RATE_2_MSB    : integer := 31;
    constant REG_MT_FB_CLOCK_RATE_2_LSB     : integer := 0;

    constant REG_MT_FB_CLOCK_RATE_3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"05";
    constant REG_MT_FB_CLOCK_RATE_3_MSB    : integer := 31;
    constant REG_MT_FB_CLOCK_RATE_3_LSB     : integer := 0;

    constant REG_MT_FB_CLOCK_RATE_4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"06";
    constant REG_MT_FB_CLOCK_RATE_4_MSB    : integer := 31;
    constant REG_MT_FB_CLOCK_RATE_4_LSB     : integer := 0;

    constant REG_MT_DSI_ON_ADDR    : std_logic_vector(9 downto 0) := "00" & x"07";
    constant REG_MT_DSI_ON_MSB    : integer := 4;
    constant REG_MT_DSI_ON_LSB     : integer := 0;
    constant REG_MT_DSI_ON_DEFAULT : std_logic_vector(4 downto 0) := '1' & x"f";

    constant REG_MT_FORCE_TRIGGER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"08";
    constant REG_MT_FORCE_TRIGGER_BIT    : integer := 0;

    constant REG_MT_TRIG_GEN_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"09";
    constant REG_MT_TRIG_GEN_RATE_MSB    : integer := 31;
    constant REG_MT_TRIG_GEN_RATE_LSB     : integer := 0;
    constant REG_MT_TRIG_GEN_RATE_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_MT_PULSE_STRETCH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0f";
    constant REG_MT_PULSE_STRETCH_MSB    : integer := 3;
    constant REG_MT_PULSE_STRETCH_LSB     : integer := 0;
    constant REG_MT_PULSE_STRETCH_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_HIT_COUNTERS_RB0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_MT_HIT_COUNTERS_RB0_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB0_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"11";
    constant REG_MT_HIT_COUNTERS_RB1_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB1_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"12";
    constant REG_MT_HIT_COUNTERS_RB2_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB2_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"13";
    constant REG_MT_HIT_COUNTERS_RB3_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB3_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_MT_HIT_COUNTERS_RB4_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB4_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"15";
    constant REG_MT_HIT_COUNTERS_RB5_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB5_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"16";
    constant REG_MT_HIT_COUNTERS_RB6_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB6_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"17";
    constant REG_MT_HIT_COUNTERS_RB7_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB7_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"18";
    constant REG_MT_HIT_COUNTERS_RB8_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB8_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"19";
    constant REG_MT_HIT_COUNTERS_RB9_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB9_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1a";
    constant REG_MT_HIT_COUNTERS_RB10_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB10_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1b";
    constant REG_MT_HIT_COUNTERS_RB11_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB11_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1c";
    constant REG_MT_HIT_COUNTERS_RB12_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB12_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1d";
    constant REG_MT_HIT_COUNTERS_RB13_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB13_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1e";
    constant REG_MT_HIT_COUNTERS_RB14_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB14_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1f";
    constant REG_MT_HIT_COUNTERS_RB15_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB15_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"20";
    constant REG_MT_HIT_COUNTERS_RB16_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB16_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"21";
    constant REG_MT_HIT_COUNTERS_RB17_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB17_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"22";
    constant REG_MT_HIT_COUNTERS_RB18_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB18_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"23";
    constant REG_MT_HIT_COUNTERS_RB19_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB19_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB20_ADDR    : std_logic_vector(9 downto 0) := "00" & x"24";
    constant REG_MT_HIT_COUNTERS_RB20_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB20_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB21_ADDR    : std_logic_vector(9 downto 0) := "00" & x"25";
    constant REG_MT_HIT_COUNTERS_RB21_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB21_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB22_ADDR    : std_logic_vector(9 downto 0) := "00" & x"26";
    constant REG_MT_HIT_COUNTERS_RB22_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB22_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB23_ADDR    : std_logic_vector(9 downto 0) := "00" & x"27";
    constant REG_MT_HIT_COUNTERS_RB23_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB23_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB24_ADDR    : std_logic_vector(9 downto 0) := "00" & x"28";
    constant REG_MT_HIT_COUNTERS_RB24_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB24_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB25_ADDR    : std_logic_vector(9 downto 0) := "00" & x"29";
    constant REG_MT_HIT_COUNTERS_RB25_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB25_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB26_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2a";
    constant REG_MT_HIT_COUNTERS_RB26_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB26_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB27_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2b";
    constant REG_MT_HIT_COUNTERS_RB27_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB27_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB28_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2c";
    constant REG_MT_HIT_COUNTERS_RB28_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB28_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB29_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2d";
    constant REG_MT_HIT_COUNTERS_RB29_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB29_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB30_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2e";
    constant REG_MT_HIT_COUNTERS_RB30_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB30_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB31_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2f";
    constant REG_MT_HIT_COUNTERS_RB31_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB31_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB32_ADDR    : std_logic_vector(9 downto 0) := "00" & x"30";
    constant REG_MT_HIT_COUNTERS_RB32_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB32_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB33_ADDR    : std_logic_vector(9 downto 0) := "00" & x"31";
    constant REG_MT_HIT_COUNTERS_RB33_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB33_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB34_ADDR    : std_logic_vector(9 downto 0) := "00" & x"32";
    constant REG_MT_HIT_COUNTERS_RB34_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB34_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB35_ADDR    : std_logic_vector(9 downto 0) := "00" & x"33";
    constant REG_MT_HIT_COUNTERS_RB35_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB35_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB36_ADDR    : std_logic_vector(9 downto 0) := "00" & x"34";
    constant REG_MT_HIT_COUNTERS_RB36_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB36_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB37_ADDR    : std_logic_vector(9 downto 0) := "00" & x"35";
    constant REG_MT_HIT_COUNTERS_RB37_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB37_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB38_ADDR    : std_logic_vector(9 downto 0) := "00" & x"36";
    constant REG_MT_HIT_COUNTERS_RB38_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB38_LSB     : integer := 0;

    constant REG_MT_HIT_COUNTERS_RB39_ADDR    : std_logic_vector(9 downto 0) := "00" & x"37";
    constant REG_MT_HIT_COUNTERS_RB39_MSB    : integer := 15;
    constant REG_MT_HIT_COUNTERS_RB39_LSB     : integer := 0;

    constant REG_MT_HIT_MASK_LT0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"40";
    constant REG_MT_HIT_MASK_LT0_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT0_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT0_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"41";
    constant REG_MT_HIT_MASK_LT1_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT1_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT1_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"42";
    constant REG_MT_HIT_MASK_LT2_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT2_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT2_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"43";
    constant REG_MT_HIT_MASK_LT3_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT3_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT3_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"44";
    constant REG_MT_HIT_MASK_LT4_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT4_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT4_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"45";
    constant REG_MT_HIT_MASK_LT5_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT5_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT5_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"46";
    constant REG_MT_HIT_MASK_LT6_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT6_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT6_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"47";
    constant REG_MT_HIT_MASK_LT7_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT7_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT7_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"48";
    constant REG_MT_HIT_MASK_LT8_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT8_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT8_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"49";
    constant REG_MT_HIT_MASK_LT9_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT9_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT9_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4a";
    constant REG_MT_HIT_MASK_LT10_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT10_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT10_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4b";
    constant REG_MT_HIT_MASK_LT11_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT11_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT11_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4c";
    constant REG_MT_HIT_MASK_LT12_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT12_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT12_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4d";
    constant REG_MT_HIT_MASK_LT13_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT13_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT13_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4e";
    constant REG_MT_HIT_MASK_LT14_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT14_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT14_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"4f";
    constant REG_MT_HIT_MASK_LT15_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT15_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT15_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"50";
    constant REG_MT_HIT_MASK_LT16_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT16_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT16_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"51";
    constant REG_MT_HIT_MASK_LT17_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT17_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT17_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"52";
    constant REG_MT_HIT_MASK_LT18_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT18_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT18_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_HIT_MASK_LT19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"53";
    constant REG_MT_HIT_MASK_LT19_MSB    : integer := 15;
    constant REG_MT_HIT_MASK_LT19_LSB     : integer := 0;
    constant REG_MT_HIT_MASK_LT19_DEFAULT : std_logic_vector(15 downto 0) := x"0000";

    constant REG_MT_FINE_DELAYS_LT0_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"60";
    constant REG_MT_FINE_DELAYS_LT0_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT0_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT0_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT0_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"60";
    constant REG_MT_FINE_DELAYS_LT0_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT0_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT0_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT1_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"61";
    constant REG_MT_FINE_DELAYS_LT1_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT1_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT1_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT1_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"61";
    constant REG_MT_FINE_DELAYS_LT1_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT1_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT1_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT2_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"62";
    constant REG_MT_FINE_DELAYS_LT2_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT2_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT2_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT2_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"62";
    constant REG_MT_FINE_DELAYS_LT2_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT2_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT2_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT3_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"63";
    constant REG_MT_FINE_DELAYS_LT3_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT3_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT3_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT3_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"63";
    constant REG_MT_FINE_DELAYS_LT3_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT3_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT3_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT4_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"64";
    constant REG_MT_FINE_DELAYS_LT4_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT4_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT4_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT4_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"64";
    constant REG_MT_FINE_DELAYS_LT4_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT4_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT4_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT5_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"65";
    constant REG_MT_FINE_DELAYS_LT5_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT5_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT5_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT5_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"65";
    constant REG_MT_FINE_DELAYS_LT5_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT5_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT5_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT6_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"66";
    constant REG_MT_FINE_DELAYS_LT6_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT6_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT6_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT6_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"66";
    constant REG_MT_FINE_DELAYS_LT6_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT6_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT6_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT7_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"67";
    constant REG_MT_FINE_DELAYS_LT7_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT7_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT7_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT7_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"67";
    constant REG_MT_FINE_DELAYS_LT7_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT7_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT7_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT8_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"68";
    constant REG_MT_FINE_DELAYS_LT8_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT8_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT8_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT8_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"68";
    constant REG_MT_FINE_DELAYS_LT8_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT8_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT8_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT9_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"69";
    constant REG_MT_FINE_DELAYS_LT9_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT9_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT9_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT9_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"69";
    constant REG_MT_FINE_DELAYS_LT9_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT9_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT9_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT10_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6a";
    constant REG_MT_FINE_DELAYS_LT10_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT10_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT10_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT10_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6a";
    constant REG_MT_FINE_DELAYS_LT10_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT10_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT10_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT11_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6b";
    constant REG_MT_FINE_DELAYS_LT11_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT11_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT11_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT11_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6b";
    constant REG_MT_FINE_DELAYS_LT11_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT11_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT11_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT12_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6c";
    constant REG_MT_FINE_DELAYS_LT12_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT12_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT12_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT12_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6c";
    constant REG_MT_FINE_DELAYS_LT12_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT12_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT12_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT13_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6d";
    constant REG_MT_FINE_DELAYS_LT13_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT13_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT13_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT13_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6d";
    constant REG_MT_FINE_DELAYS_LT13_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT13_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT13_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT14_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6e";
    constant REG_MT_FINE_DELAYS_LT14_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT14_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT14_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT14_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6e";
    constant REG_MT_FINE_DELAYS_LT14_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT14_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT14_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT15_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6f";
    constant REG_MT_FINE_DELAYS_LT15_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT15_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT15_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT15_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"6f";
    constant REG_MT_FINE_DELAYS_LT15_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT15_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT15_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT16_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"70";
    constant REG_MT_FINE_DELAYS_LT16_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT16_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT16_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT16_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"70";
    constant REG_MT_FINE_DELAYS_LT16_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT16_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT16_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT17_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"71";
    constant REG_MT_FINE_DELAYS_LT17_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT17_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT17_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT17_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"71";
    constant REG_MT_FINE_DELAYS_LT17_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT17_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT17_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT18_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"72";
    constant REG_MT_FINE_DELAYS_LT18_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT18_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT18_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT18_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"72";
    constant REG_MT_FINE_DELAYS_LT18_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT18_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT18_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT19_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"73";
    constant REG_MT_FINE_DELAYS_LT19_CH0_MSB    : integer := 4;
    constant REG_MT_FINE_DELAYS_LT19_CH0_LSB     : integer := 0;
    constant REG_MT_FINE_DELAYS_LT19_CH0_DEFAULT : std_logic_vector(4 downto 0) := '0' & x"0";

    constant REG_MT_FINE_DELAYS_LT19_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"73";
    constant REG_MT_FINE_DELAYS_LT19_CH1_MSB    : integer := 12;
    constant REG_MT_FINE_DELAYS_LT19_CH1_LSB     : integer := 8;
    constant REG_MT_FINE_DELAYS_LT19_CH1_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"0";

    constant REG_MT_COARSE_DELAYS_LT0_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"80";
    constant REG_MT_COARSE_DELAYS_LT0_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT0_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT0_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT0_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"80";
    constant REG_MT_COARSE_DELAYS_LT0_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT0_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT0_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT1_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"81";
    constant REG_MT_COARSE_DELAYS_LT1_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT1_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT1_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT1_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"81";
    constant REG_MT_COARSE_DELAYS_LT1_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT1_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT1_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT2_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"82";
    constant REG_MT_COARSE_DELAYS_LT2_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT2_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT2_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT2_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"82";
    constant REG_MT_COARSE_DELAYS_LT2_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT2_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT2_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT3_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"83";
    constant REG_MT_COARSE_DELAYS_LT3_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT3_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT3_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT3_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"83";
    constant REG_MT_COARSE_DELAYS_LT3_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT3_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT3_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT4_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"84";
    constant REG_MT_COARSE_DELAYS_LT4_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT4_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT4_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT4_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"84";
    constant REG_MT_COARSE_DELAYS_LT4_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT4_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT4_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT5_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"85";
    constant REG_MT_COARSE_DELAYS_LT5_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT5_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT5_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT5_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"85";
    constant REG_MT_COARSE_DELAYS_LT5_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT5_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT5_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT6_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"86";
    constant REG_MT_COARSE_DELAYS_LT6_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT6_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT6_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT6_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"86";
    constant REG_MT_COARSE_DELAYS_LT6_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT6_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT6_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT7_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"87";
    constant REG_MT_COARSE_DELAYS_LT7_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT7_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT7_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT7_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"87";
    constant REG_MT_COARSE_DELAYS_LT7_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT7_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT7_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT8_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"88";
    constant REG_MT_COARSE_DELAYS_LT8_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT8_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT8_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT8_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"88";
    constant REG_MT_COARSE_DELAYS_LT8_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT8_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT8_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT9_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"89";
    constant REG_MT_COARSE_DELAYS_LT9_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT9_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT9_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT9_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"89";
    constant REG_MT_COARSE_DELAYS_LT9_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT9_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT9_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT10_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8a";
    constant REG_MT_COARSE_DELAYS_LT10_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT10_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT10_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT10_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8a";
    constant REG_MT_COARSE_DELAYS_LT10_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT10_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT10_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT11_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8b";
    constant REG_MT_COARSE_DELAYS_LT11_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT11_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT11_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT11_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8b";
    constant REG_MT_COARSE_DELAYS_LT11_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT11_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT11_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT12_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8c";
    constant REG_MT_COARSE_DELAYS_LT12_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT12_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT12_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT12_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8c";
    constant REG_MT_COARSE_DELAYS_LT12_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT12_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT12_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT13_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8d";
    constant REG_MT_COARSE_DELAYS_LT13_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT13_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT13_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT13_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8d";
    constant REG_MT_COARSE_DELAYS_LT13_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT13_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT13_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT14_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8e";
    constant REG_MT_COARSE_DELAYS_LT14_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT14_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT14_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT14_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8e";
    constant REG_MT_COARSE_DELAYS_LT14_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT14_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT14_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT15_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8f";
    constant REG_MT_COARSE_DELAYS_LT15_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT15_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT15_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT15_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"8f";
    constant REG_MT_COARSE_DELAYS_LT15_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT15_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT15_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT16_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"90";
    constant REG_MT_COARSE_DELAYS_LT16_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT16_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT16_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT16_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"90";
    constant REG_MT_COARSE_DELAYS_LT16_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT16_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT16_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT17_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"91";
    constant REG_MT_COARSE_DELAYS_LT17_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT17_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT17_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT17_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"91";
    constant REG_MT_COARSE_DELAYS_LT17_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT17_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT17_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT18_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"92";
    constant REG_MT_COARSE_DELAYS_LT18_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT18_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT18_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT18_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"92";
    constant REG_MT_COARSE_DELAYS_LT18_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT18_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT18_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_COARSE_DELAYS_LT19_CH0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"93";
    constant REG_MT_COARSE_DELAYS_LT19_CH0_MSB    : integer := 3;
    constant REG_MT_COARSE_DELAYS_LT19_CH0_LSB     : integer := 0;
    constant REG_MT_COARSE_DELAYS_LT19_CH0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_MT_COARSE_DELAYS_LT19_CH1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"93";
    constant REG_MT_COARSE_DELAYS_LT19_CH1_MSB    : integer := 7;
    constant REG_MT_COARSE_DELAYS_LT19_CH1_LSB     : integer := 4;
    constant REG_MT_COARSE_DELAYS_LT19_CH1_DEFAULT : std_logic_vector(7 downto 4) := x"0";

    constant REG_MT_POSNEGS_LT0_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"00";
    constant REG_MT_POSNEGS_LT0_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT0_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT0_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"00";
    constant REG_MT_POSNEGS_LT0_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT0_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT1_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"01";
    constant REG_MT_POSNEGS_LT1_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT1_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT1_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"01";
    constant REG_MT_POSNEGS_LT1_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT1_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT2_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"02";
    constant REG_MT_POSNEGS_LT2_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT2_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT2_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"02";
    constant REG_MT_POSNEGS_LT2_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT2_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT3_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"03";
    constant REG_MT_POSNEGS_LT3_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT3_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT3_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"03";
    constant REG_MT_POSNEGS_LT3_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT3_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT4_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"04";
    constant REG_MT_POSNEGS_LT4_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT4_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT4_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"04";
    constant REG_MT_POSNEGS_LT4_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT4_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT5_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"05";
    constant REG_MT_POSNEGS_LT5_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT5_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT5_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"05";
    constant REG_MT_POSNEGS_LT5_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT5_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT6_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"06";
    constant REG_MT_POSNEGS_LT6_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT6_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT6_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"06";
    constant REG_MT_POSNEGS_LT6_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT6_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT7_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"07";
    constant REG_MT_POSNEGS_LT7_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT7_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT7_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"07";
    constant REG_MT_POSNEGS_LT7_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT7_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT8_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"08";
    constant REG_MT_POSNEGS_LT8_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT8_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT8_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"08";
    constant REG_MT_POSNEGS_LT8_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT8_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT9_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"09";
    constant REG_MT_POSNEGS_LT9_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT9_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT9_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"09";
    constant REG_MT_POSNEGS_LT9_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT9_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT10_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0a";
    constant REG_MT_POSNEGS_LT10_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT10_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT10_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0a";
    constant REG_MT_POSNEGS_LT10_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT10_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT11_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0b";
    constant REG_MT_POSNEGS_LT11_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT11_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT11_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0b";
    constant REG_MT_POSNEGS_LT11_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT11_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT12_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0c";
    constant REG_MT_POSNEGS_LT12_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT12_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT12_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0c";
    constant REG_MT_POSNEGS_LT12_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT12_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT13_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0d";
    constant REG_MT_POSNEGS_LT13_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT13_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT13_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0d";
    constant REG_MT_POSNEGS_LT13_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT13_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT14_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0e";
    constant REG_MT_POSNEGS_LT14_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT14_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT14_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0e";
    constant REG_MT_POSNEGS_LT14_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT14_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT15_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0f";
    constant REG_MT_POSNEGS_LT15_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT15_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT15_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"0f";
    constant REG_MT_POSNEGS_LT15_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT15_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT16_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"10";
    constant REG_MT_POSNEGS_LT16_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT16_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT16_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"10";
    constant REG_MT_POSNEGS_LT16_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT16_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT17_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"11";
    constant REG_MT_POSNEGS_LT17_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT17_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT17_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"11";
    constant REG_MT_POSNEGS_LT17_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT17_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT18_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"12";
    constant REG_MT_POSNEGS_LT18_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT18_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT18_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"12";
    constant REG_MT_POSNEGS_LT18_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT18_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT19_CH0_ADDR    : std_logic_vector(9 downto 0) := "01" & x"13";
    constant REG_MT_POSNEGS_LT19_CH0_BIT    : integer := 0;
    constant REG_MT_POSNEGS_LT19_CH0_DEFAULT : std_logic := '0';

    constant REG_MT_POSNEGS_LT19_CH1_ADDR    : std_logic_vector(9 downto 0) := "01" & x"13";
    constant REG_MT_POSNEGS_LT19_CH1_BIT    : integer := 4;
    constant REG_MT_POSNEGS_LT19_CH1_DEFAULT : std_logic := '0';

    constant REG_MT_XADC_CALIBRATION_ADDR    : std_logic_vector(9 downto 0) := "01" & x"20";
    constant REG_MT_XADC_CALIBRATION_MSB    : integer := 11;
    constant REG_MT_XADC_CALIBRATION_LSB     : integer := 0;

    constant REG_MT_XADC_VCCPINT_ADDR    : std_logic_vector(9 downto 0) := "01" & x"20";
    constant REG_MT_XADC_VCCPINT_MSB    : integer := 27;
    constant REG_MT_XADC_VCCPINT_LSB     : integer := 16;

    constant REG_MT_XADC_VCCPAUX_ADDR    : std_logic_vector(9 downto 0) := "01" & x"21";
    constant REG_MT_XADC_VCCPAUX_MSB    : integer := 11;
    constant REG_MT_XADC_VCCPAUX_LSB     : integer := 0;

    constant REG_MT_XADC_VCCODDR_ADDR    : std_logic_vector(9 downto 0) := "01" & x"21";
    constant REG_MT_XADC_VCCODDR_MSB    : integer := 27;
    constant REG_MT_XADC_VCCODDR_LSB     : integer := 16;

    constant REG_MT_XADC_TEMP_ADDR    : std_logic_vector(9 downto 0) := "01" & x"22";
    constant REG_MT_XADC_TEMP_MSB    : integer := 11;
    constant REG_MT_XADC_TEMP_LSB     : integer := 0;

    constant REG_MT_XADC_VCCINT_ADDR    : std_logic_vector(9 downto 0) := "01" & x"22";
    constant REG_MT_XADC_VCCINT_MSB    : integer := 27;
    constant REG_MT_XADC_VCCINT_LSB     : integer := 16;

    constant REG_MT_XADC_VCCAUX_ADDR    : std_logic_vector(9 downto 0) := "01" & x"23";
    constant REG_MT_XADC_VCCAUX_MSB    : integer := 11;
    constant REG_MT_XADC_VCCAUX_LSB     : integer := 0;

    constant REG_MT_XADC_VCCBRAM_ADDR    : std_logic_vector(9 downto 0) := "01" & x"23";
    constant REG_MT_XADC_VCCBRAM_MSB    : integer := 27;
    constant REG_MT_XADC_VCCBRAM_LSB     : integer := 16;

    constant REG_MT_HOG_GLOBAL_DATE_ADDR    : std_logic_vector(9 downto 0) := "10" & x"00";
    constant REG_MT_HOG_GLOBAL_DATE_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_DATE_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_TIME_ADDR    : std_logic_vector(9 downto 0) := "10" & x"01";
    constant REG_MT_HOG_GLOBAL_TIME_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_TIME_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"02";
    constant REG_MT_HOG_GLOBAL_VER_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_VER_LSB     : integer := 0;

    constant REG_MT_HOG_GLOBAL_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"03";
    constant REG_MT_HOG_GLOBAL_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_GLOBAL_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_TOP_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"04";
    constant REG_MT_HOG_TOP_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_TOP_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_TOP_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"05";
    constant REG_MT_HOG_TOP_VER_MSB    : integer := 31;
    constant REG_MT_HOG_TOP_VER_LSB     : integer := 0;

    constant REG_MT_HOG_HOG_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"06";
    constant REG_MT_HOG_HOG_SHA_MSB    : integer := 31;
    constant REG_MT_HOG_HOG_SHA_LSB     : integer := 0;

    constant REG_MT_HOG_HOG_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"07";
    constant REG_MT_HOG_HOG_VER_MSB    : integer := 31;
    constant REG_MT_HOG_HOG_VER_LSB     : integer := 0;


end registers;
