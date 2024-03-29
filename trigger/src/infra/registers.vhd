library IEEE;
use IEEE.STD_LOGIC_1164.all;

-----> !! This package is auto-generated from an address table file using <repo_root>/scripts/generate_registers.py !! <-----
package registers is

    --============================================================================
    --       >>> MT Module <<<    base address: 0x00000000
    --
    -- Implements various control and monitoring functions of the DRS Logic
    --============================================================================

    constant REG_MT_NUM_REGS : integer := 169;
    constant REG_MT_ADDRESS_MSB : integer := 9;
    constant REG_MT_ADDRESS_LSB : integer := 0;
    constant REG_LOOPBACK_ADDR    : std_logic_vector(9 downto 0) := "00" & x"00";
    constant REG_LOOPBACK_MSB    : integer := 31;
    constant REG_LOOPBACK_LSB     : integer := 0;
    constant REG_LOOPBACK_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_CLOCK_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"01";
    constant REG_CLOCK_RATE_MSB    : integer := 31;
    constant REG_CLOCK_RATE_LSB     : integer := 0;

    constant REG_FB_CLOCK_RATE_0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"02";
    constant REG_FB_CLOCK_RATE_0_MSB    : integer := 31;
    constant REG_FB_CLOCK_RATE_0_LSB     : integer := 0;

    constant REG_FB_CLOCK_RATE_1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"03";
    constant REG_FB_CLOCK_RATE_1_MSB    : integer := 31;
    constant REG_FB_CLOCK_RATE_1_LSB     : integer := 0;

    constant REG_FB_CLOCK_RATE_2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"04";
    constant REG_FB_CLOCK_RATE_2_MSB    : integer := 31;
    constant REG_FB_CLOCK_RATE_2_LSB     : integer := 0;

    constant REG_FB_CLOCK_RATE_3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"05";
    constant REG_FB_CLOCK_RATE_3_MSB    : integer := 31;
    constant REG_FB_CLOCK_RATE_3_LSB     : integer := 0;

    constant REG_FB_CLOCK_RATE_4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"06";
    constant REG_FB_CLOCK_RATE_4_MSB    : integer := 31;
    constant REG_FB_CLOCK_RATE_4_LSB     : integer := 0;

    constant REG_DSI_ON_ADDR    : std_logic_vector(9 downto 0) := "00" & x"07";
    constant REG_DSI_ON_MSB    : integer := 4;
    constant REG_DSI_ON_LSB     : integer := 0;
    constant REG_DSI_ON_DEFAULT : std_logic_vector(4 downto 0) := '1' & x"f";

    constant REG_FORCE_TRIGGER_ADDR    : std_logic_vector(9 downto 0) := "00" & x"08";
    constant REG_FORCE_TRIGGER_BIT    : integer := 0;

    constant REG_TRIG_GEN_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"09";
    constant REG_TRIG_GEN_RATE_MSB    : integer := 31;
    constant REG_TRIG_GEN_RATE_LSB     : integer := 0;
    constant REG_TRIG_GEN_RATE_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_RESYNC_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0a";
    constant REG_RESYNC_BIT    : integer := 0;

    constant REG_ANY_TRIG_IS_GLOBAL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0b";
    constant REG_ANY_TRIG_IS_GLOBAL_BIT    : integer := 0;
    constant REG_ANY_TRIG_IS_GLOBAL_DEFAULT : std_logic := '0';

    constant REG_TRACK_TRIG_IS_GLOBAL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0b";
    constant REG_TRACK_TRIG_IS_GLOBAL_BIT    : integer := 1;
    constant REG_TRACK_TRIG_IS_GLOBAL_DEFAULT : std_logic := '0';

    constant REG_TRACK_CENTRAL_IS_GLOBAL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0b";
    constant REG_TRACK_CENTRAL_IS_GLOBAL_BIT    : integer := 2;
    constant REG_TRACK_CENTRAL_IS_GLOBAL_DEFAULT : std_logic := '0';

    constant REG_EVENT_CNT_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0c";
    constant REG_EVENT_CNT_RESET_BIT    : integer := 0;

    constant REG_EVENT_CNT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0d";
    constant REG_EVENT_CNT_MSB    : integer := 31;
    constant REG_EVENT_CNT_LSB     : integer := 0;

    constant REG_TIU_EMULATION_MODE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0e";
    constant REG_TIU_EMULATION_MODE_BIT    : integer := 0;
    constant REG_TIU_EMULATION_MODE_DEFAULT : std_logic := '0';

    constant REG_TIU_USE_AUX_LINK_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0e";
    constant REG_TIU_USE_AUX_LINK_BIT    : integer := 1;
    constant REG_TIU_USE_AUX_LINK_DEFAULT : std_logic := '0';

    constant REG_TIU_EMU_BUSY_CNT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0e";
    constant REG_TIU_EMU_BUSY_CNT_MSB    : integer := 31;
    constant REG_TIU_EMU_BUSY_CNT_LSB     : integer := 14;
    constant REG_TIU_EMU_BUSY_CNT_DEFAULT : std_logic_vector(31 downto 14) := "00" & x"c350";

    constant REG_TIU_BAD_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0f";
    constant REG_TIU_BAD_BIT    : integer := 0;

    constant REG_LT_INPUT_STRETCH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0f";
    constant REG_LT_INPUT_STRETCH_MSB    : integer := 7;
    constant REG_LT_INPUT_STRETCH_LSB     : integer := 4;
    constant REG_LT_INPUT_STRETCH_DEFAULT : std_logic_vector(7 downto 4) := x"f";

    constant REG_RB_INTEGRATION_WINDOW_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0f";
    constant REG_RB_INTEGRATION_WINDOW_MSB    : integer := 12;
    constant REG_RB_INTEGRATION_WINDOW_LSB     : integer := 8;
    constant REG_RB_INTEGRATION_WINDOW_DEFAULT : std_logic_vector(12 downto 8) := '0' & x"1";

    constant REG_RB_READ_ALL_CHANNELS_ADDR    : std_logic_vector(9 downto 0) := "00" & x"0f";
    constant REG_RB_READ_ALL_CHANNELS_BIT    : integer := 13;
    constant REG_RB_READ_ALL_CHANNELS_DEFAULT : std_logic := '1';

    constant REG_EVENT_QUEUE_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"10";
    constant REG_EVENT_QUEUE_RESET_BIT    : integer := 0;

    constant REG_EVENT_QUEUE_DATA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"11";
    constant REG_EVENT_QUEUE_DATA_MSB    : integer := 31;
    constant REG_EVENT_QUEUE_DATA_LSB     : integer := 0;

    constant REG_EVENT_QUEUE_FULL_ADDR    : std_logic_vector(9 downto 0) := "00" & x"12";
    constant REG_EVENT_QUEUE_FULL_BIT    : integer := 0;

    constant REG_EVENT_QUEUE_EMPTY_ADDR    : std_logic_vector(9 downto 0) := "00" & x"12";
    constant REG_EVENT_QUEUE_EMPTY_BIT    : integer := 1;

    constant REG_EVENT_QUEUE_SIZE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"13";
    constant REG_EVENT_QUEUE_SIZE_MSB    : integer := 31;
    constant REG_EVENT_QUEUE_SIZE_LSB     : integer := 16;

    constant REG_INNER_TOF_THRESH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_INNER_TOF_THRESH_MSB    : integer := 7;
    constant REG_INNER_TOF_THRESH_LSB     : integer := 0;
    constant REG_INNER_TOF_THRESH_DEFAULT : std_logic_vector(7 downto 0) := x"03";

    constant REG_OUTER_TOF_THRESH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_OUTER_TOF_THRESH_MSB    : integer := 15;
    constant REG_OUTER_TOF_THRESH_LSB     : integer := 8;
    constant REG_OUTER_TOF_THRESH_DEFAULT : std_logic_vector(15 downto 8) := x"03";

    constant REG_TOTAL_TOF_THRESH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_TOTAL_TOF_THRESH_MSB    : integer := 23;
    constant REG_TOTAL_TOF_THRESH_LSB     : integer := 16;
    constant REG_TOTAL_TOF_THRESH_DEFAULT : std_logic_vector(23 downto 16) := x"08";

    constant REG_GAPS_TRIGGER_EN_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_GAPS_TRIGGER_EN_BIT    : integer := 24;
    constant REG_GAPS_TRIGGER_EN_DEFAULT : std_logic := '0';

    constant REG_REQUIRE_BETA_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_REQUIRE_BETA_BIT    : integer := 25;
    constant REG_REQUIRE_BETA_DEFAULT : std_logic := '1';

    constant REG_HIT_THRESH_ADDR    : std_logic_vector(9 downto 0) := "00" & x"14";
    constant REG_HIT_THRESH_MSB    : integer := 29;
    constant REG_HIT_THRESH_LSB     : integer := 28;
    constant REG_HIT_THRESH_DEFAULT : std_logic_vector(29 downto 28) := "00";

    constant REG_TRIGGER_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"17";
    constant REG_TRIGGER_RATE_MSB    : integer := 23;
    constant REG_TRIGGER_RATE_LSB     : integer := 0;

    constant REG_LOST_TRIGGER_RATE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"18";
    constant REG_LOST_TRIGGER_RATE_MSB    : integer := 23;
    constant REG_LOST_TRIGGER_RATE_LSB     : integer := 0;

    constant REG_LT_LINK_READY0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1a";
    constant REG_LT_LINK_READY0_MSB    : integer := 9;
    constant REG_LT_LINK_READY0_LSB     : integer := 0;

    constant REG_LT_LINK_READY1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1b";
    constant REG_LT_LINK_READY1_MSB    : integer := 9;
    constant REG_LT_LINK_READY1_LSB     : integer := 0;

    constant REG_LT_LINK_READY2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1c";
    constant REG_LT_LINK_READY2_MSB    : integer := 9;
    constant REG_LT_LINK_READY2_LSB     : integer := 0;

    constant REG_LT_LINK_READY3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1d";
    constant REG_LT_LINK_READY3_MSB    : integer := 9;
    constant REG_LT_LINK_READY3_LSB     : integer := 0;

    constant REG_LT_LINK_READY4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"1e";
    constant REG_LT_LINK_READY4_MSB    : integer := 9;
    constant REG_LT_LINK_READY4_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"20";
    constant REG_HIT_COUNTERS_LT0_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT0_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"21";
    constant REG_HIT_COUNTERS_LT1_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT1_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"22";
    constant REG_HIT_COUNTERS_LT2_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT2_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"23";
    constant REG_HIT_COUNTERS_LT3_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT3_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"24";
    constant REG_HIT_COUNTERS_LT4_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT4_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"25";
    constant REG_HIT_COUNTERS_LT5_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT5_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"26";
    constant REG_HIT_COUNTERS_LT6_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT6_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"27";
    constant REG_HIT_COUNTERS_LT7_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT7_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"28";
    constant REG_HIT_COUNTERS_LT8_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT8_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"29";
    constant REG_HIT_COUNTERS_LT9_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT9_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2a";
    constant REG_HIT_COUNTERS_LT10_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT10_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2b";
    constant REG_HIT_COUNTERS_LT11_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT11_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2c";
    constant REG_HIT_COUNTERS_LT12_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT12_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2d";
    constant REG_HIT_COUNTERS_LT13_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT13_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2e";
    constant REG_HIT_COUNTERS_LT14_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT14_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"2f";
    constant REG_HIT_COUNTERS_LT15_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT15_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"30";
    constant REG_HIT_COUNTERS_LT16_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT16_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"31";
    constant REG_HIT_COUNTERS_LT17_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT17_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"32";
    constant REG_HIT_COUNTERS_LT18_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT18_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"33";
    constant REG_HIT_COUNTERS_LT19_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT19_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT20_ADDR    : std_logic_vector(9 downto 0) := "00" & x"34";
    constant REG_HIT_COUNTERS_LT20_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT20_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT21_ADDR    : std_logic_vector(9 downto 0) := "00" & x"35";
    constant REG_HIT_COUNTERS_LT21_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT21_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT22_ADDR    : std_logic_vector(9 downto 0) := "00" & x"36";
    constant REG_HIT_COUNTERS_LT22_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT22_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT23_ADDR    : std_logic_vector(9 downto 0) := "00" & x"37";
    constant REG_HIT_COUNTERS_LT23_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT23_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_LT24_ADDR    : std_logic_vector(9 downto 0) := "00" & x"38";
    constant REG_HIT_COUNTERS_LT24_MSB    : integer := 23;
    constant REG_HIT_COUNTERS_LT24_LSB     : integer := 0;

    constant REG_HIT_COUNTERS_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"39";
    constant REG_HIT_COUNTERS_RESET_BIT    : integer := 0;

    constant REG_HIT_COUNTERS_SNAP_ADDR    : std_logic_vector(9 downto 0) := "00" & x"3a";
    constant REG_HIT_COUNTERS_SNAP_BIT    : integer := 0;
    constant REG_HIT_COUNTERS_SNAP_DEFAULT : std_logic := '1';

    constant REG_ETH_RX_BAD_FRAME_CNT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"3d";
    constant REG_ETH_RX_BAD_FRAME_CNT_MSB    : integer := 15;
    constant REG_ETH_RX_BAD_FRAME_CNT_LSB     : integer := 0;

    constant REG_ETH_RX_BAD_FCS_CNT_ADDR    : std_logic_vector(9 downto 0) := "00" & x"3d";
    constant REG_ETH_RX_BAD_FCS_CNT_MSB    : integer := 31;
    constant REG_ETH_RX_BAD_FCS_CNT_LSB     : integer := 16;

    constant REG_ANY_TRIG_PRESCALE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"40";
    constant REG_ANY_TRIG_PRESCALE_MSB    : integer := 31;
    constant REG_ANY_TRIG_PRESCALE_LSB     : integer := 0;
    constant REG_ANY_TRIG_PRESCALE_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_TRACK_TRIGGER_PRESCALE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"41";
    constant REG_TRACK_TRIGGER_PRESCALE_MSB    : integer := 31;
    constant REG_TRACK_TRIGGER_PRESCALE_LSB     : integer := 0;
    constant REG_TRACK_TRIGGER_PRESCALE_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_TRACK_CENTRAL_PRESCALE_ADDR    : std_logic_vector(9 downto 0) := "00" & x"42";
    constant REG_TRACK_CENTRAL_PRESCALE_MSB    : integer := 31;
    constant REG_TRACK_CENTRAL_PRESCALE_LSB     : integer := 0;
    constant REG_TRACK_CENTRAL_PRESCALE_DEFAULT : std_logic_vector(31 downto 0) := x"00000000";

    constant REG_CHANNEL_MASK_LT0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"50";
    constant REG_CHANNEL_MASK_LT0_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT0_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT0_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"51";
    constant REG_CHANNEL_MASK_LT1_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT1_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT1_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"52";
    constant REG_CHANNEL_MASK_LT2_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT2_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT2_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"53";
    constant REG_CHANNEL_MASK_LT3_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT3_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT3_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"54";
    constant REG_CHANNEL_MASK_LT4_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT4_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT4_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"55";
    constant REG_CHANNEL_MASK_LT5_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT5_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT5_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"56";
    constant REG_CHANNEL_MASK_LT6_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT6_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT6_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"57";
    constant REG_CHANNEL_MASK_LT7_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT7_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT7_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"58";
    constant REG_CHANNEL_MASK_LT8_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT8_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT8_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"59";
    constant REG_CHANNEL_MASK_LT9_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT9_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT9_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5a";
    constant REG_CHANNEL_MASK_LT10_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT10_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT10_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5b";
    constant REG_CHANNEL_MASK_LT11_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT11_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT11_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5c";
    constant REG_CHANNEL_MASK_LT12_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT12_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT12_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5d";
    constant REG_CHANNEL_MASK_LT13_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT13_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT13_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5e";
    constant REG_CHANNEL_MASK_LT14_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT14_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT14_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"5f";
    constant REG_CHANNEL_MASK_LT15_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT15_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT15_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"60";
    constant REG_CHANNEL_MASK_LT16_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT16_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT16_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"61";
    constant REG_CHANNEL_MASK_LT17_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT17_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT17_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"62";
    constant REG_CHANNEL_MASK_LT18_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT18_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT18_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"63";
    constant REG_CHANNEL_MASK_LT19_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT19_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT19_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT20_ADDR    : std_logic_vector(9 downto 0) := "00" & x"64";
    constant REG_CHANNEL_MASK_LT20_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT20_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT20_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT21_ADDR    : std_logic_vector(9 downto 0) := "00" & x"65";
    constant REG_CHANNEL_MASK_LT21_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT21_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT21_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT22_ADDR    : std_logic_vector(9 downto 0) := "00" & x"66";
    constant REG_CHANNEL_MASK_LT22_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT22_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT22_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT23_ADDR    : std_logic_vector(9 downto 0) := "00" & x"67";
    constant REG_CHANNEL_MASK_LT23_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT23_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT23_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_CHANNEL_MASK_LT24_ADDR    : std_logic_vector(9 downto 0) := "00" & x"68";
    constant REG_CHANNEL_MASK_LT24_MSB    : integer := 7;
    constant REG_CHANNEL_MASK_LT24_LSB     : integer := 0;
    constant REG_CHANNEL_MASK_LT24_DEFAULT : std_logic_vector(7 downto 0) := x"00";

    constant REG_COARSE_DELAYS_LT0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c0";
    constant REG_COARSE_DELAYS_LT0_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT0_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT0_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c1";
    constant REG_COARSE_DELAYS_LT1_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT1_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT1_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c2";
    constant REG_COARSE_DELAYS_LT2_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT2_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT2_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c3";
    constant REG_COARSE_DELAYS_LT3_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT3_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT3_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c4";
    constant REG_COARSE_DELAYS_LT4_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT4_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT4_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c5";
    constant REG_COARSE_DELAYS_LT5_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT5_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT5_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c6";
    constant REG_COARSE_DELAYS_LT6_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT6_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT6_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c7";
    constant REG_COARSE_DELAYS_LT7_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT7_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT7_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c8";
    constant REG_COARSE_DELAYS_LT8_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT8_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT8_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"c9";
    constant REG_COARSE_DELAYS_LT9_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT9_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT9_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ca";
    constant REG_COARSE_DELAYS_LT10_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT10_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT10_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"cb";
    constant REG_COARSE_DELAYS_LT11_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT11_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT11_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"cc";
    constant REG_COARSE_DELAYS_LT12_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT12_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT12_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"cd";
    constant REG_COARSE_DELAYS_LT13_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT13_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT13_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ce";
    constant REG_COARSE_DELAYS_LT14_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT14_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT14_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"cf";
    constant REG_COARSE_DELAYS_LT15_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT15_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT15_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d0";
    constant REG_COARSE_DELAYS_LT16_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT16_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT16_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d1";
    constant REG_COARSE_DELAYS_LT17_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT17_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT17_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d2";
    constant REG_COARSE_DELAYS_LT18_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT18_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT18_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d3";
    constant REG_COARSE_DELAYS_LT19_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT19_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT19_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT20_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d4";
    constant REG_COARSE_DELAYS_LT20_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT20_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT20_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT21_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d5";
    constant REG_COARSE_DELAYS_LT21_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT21_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT21_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT22_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d6";
    constant REG_COARSE_DELAYS_LT22_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT22_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT22_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT23_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d7";
    constant REG_COARSE_DELAYS_LT23_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT23_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT23_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT24_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d8";
    constant REG_COARSE_DELAYS_LT24_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT24_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT24_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT25_ADDR    : std_logic_vector(9 downto 0) := "00" & x"d9";
    constant REG_COARSE_DELAYS_LT25_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT25_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT25_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT26_ADDR    : std_logic_vector(9 downto 0) := "00" & x"da";
    constant REG_COARSE_DELAYS_LT26_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT26_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT26_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT27_ADDR    : std_logic_vector(9 downto 0) := "00" & x"db";
    constant REG_COARSE_DELAYS_LT27_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT27_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT27_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT28_ADDR    : std_logic_vector(9 downto 0) := "00" & x"dc";
    constant REG_COARSE_DELAYS_LT28_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT28_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT28_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT29_ADDR    : std_logic_vector(9 downto 0) := "00" & x"dd";
    constant REG_COARSE_DELAYS_LT29_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT29_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT29_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT30_ADDR    : std_logic_vector(9 downto 0) := "00" & x"de";
    constant REG_COARSE_DELAYS_LT30_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT30_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT30_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT31_ADDR    : std_logic_vector(9 downto 0) := "00" & x"df";
    constant REG_COARSE_DELAYS_LT31_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT31_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT31_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT32_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e0";
    constant REG_COARSE_DELAYS_LT32_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT32_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT32_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT33_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e1";
    constant REG_COARSE_DELAYS_LT33_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT33_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT33_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT34_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e2";
    constant REG_COARSE_DELAYS_LT34_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT34_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT34_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT35_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e3";
    constant REG_COARSE_DELAYS_LT35_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT35_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT35_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT36_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e4";
    constant REG_COARSE_DELAYS_LT36_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT36_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT36_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT37_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e5";
    constant REG_COARSE_DELAYS_LT37_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT37_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT37_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT38_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e6";
    constant REG_COARSE_DELAYS_LT38_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT38_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT38_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT39_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e7";
    constant REG_COARSE_DELAYS_LT39_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT39_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT39_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT40_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e8";
    constant REG_COARSE_DELAYS_LT40_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT40_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT40_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT41_ADDR    : std_logic_vector(9 downto 0) := "00" & x"e9";
    constant REG_COARSE_DELAYS_LT41_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT41_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT41_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT42_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ea";
    constant REG_COARSE_DELAYS_LT42_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT42_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT42_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT43_ADDR    : std_logic_vector(9 downto 0) := "00" & x"eb";
    constant REG_COARSE_DELAYS_LT43_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT43_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT43_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT44_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ec";
    constant REG_COARSE_DELAYS_LT44_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT44_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT44_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT45_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ed";
    constant REG_COARSE_DELAYS_LT45_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT45_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT45_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT46_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ee";
    constant REG_COARSE_DELAYS_LT46_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT46_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT46_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT47_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ef";
    constant REG_COARSE_DELAYS_LT47_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT47_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT47_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT48_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f0";
    constant REG_COARSE_DELAYS_LT48_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT48_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT48_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_COARSE_DELAYS_LT49_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f1";
    constant REG_COARSE_DELAYS_LT49_MSB    : integer := 3;
    constant REG_COARSE_DELAYS_LT49_LSB     : integer := 0;
    constant REG_COARSE_DELAYS_LT49_DEFAULT : std_logic_vector(3 downto 0) := x"0";

    constant REG_RB_READOUT_CNTS_CNTS_0_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f2";
    constant REG_RB_READOUT_CNTS_CNTS_0_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_0_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_1_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f2";
    constant REG_RB_READOUT_CNTS_CNTS_1_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_1_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_2_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f2";
    constant REG_RB_READOUT_CNTS_CNTS_2_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_2_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_3_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f2";
    constant REG_RB_READOUT_CNTS_CNTS_3_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_3_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_4_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f3";
    constant REG_RB_READOUT_CNTS_CNTS_4_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_4_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_5_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f3";
    constant REG_RB_READOUT_CNTS_CNTS_5_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_5_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_6_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f3";
    constant REG_RB_READOUT_CNTS_CNTS_6_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_6_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_7_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f3";
    constant REG_RB_READOUT_CNTS_CNTS_7_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_7_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_8_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f4";
    constant REG_RB_READOUT_CNTS_CNTS_8_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_8_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_9_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f4";
    constant REG_RB_READOUT_CNTS_CNTS_9_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_9_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_10_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f4";
    constant REG_RB_READOUT_CNTS_CNTS_10_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_10_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_11_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f4";
    constant REG_RB_READOUT_CNTS_CNTS_11_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_11_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_12_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f5";
    constant REG_RB_READOUT_CNTS_CNTS_12_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_12_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_13_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f5";
    constant REG_RB_READOUT_CNTS_CNTS_13_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_13_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_14_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f5";
    constant REG_RB_READOUT_CNTS_CNTS_14_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_14_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_15_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f5";
    constant REG_RB_READOUT_CNTS_CNTS_15_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_15_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_16_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f6";
    constant REG_RB_READOUT_CNTS_CNTS_16_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_16_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_17_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f6";
    constant REG_RB_READOUT_CNTS_CNTS_17_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_17_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_18_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f6";
    constant REG_RB_READOUT_CNTS_CNTS_18_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_18_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_19_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f6";
    constant REG_RB_READOUT_CNTS_CNTS_19_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_19_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_20_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f7";
    constant REG_RB_READOUT_CNTS_CNTS_20_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_20_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_21_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f7";
    constant REG_RB_READOUT_CNTS_CNTS_21_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_21_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_22_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f7";
    constant REG_RB_READOUT_CNTS_CNTS_22_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_22_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_23_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f7";
    constant REG_RB_READOUT_CNTS_CNTS_23_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_23_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_24_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f8";
    constant REG_RB_READOUT_CNTS_CNTS_24_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_24_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_25_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f8";
    constant REG_RB_READOUT_CNTS_CNTS_25_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_25_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_26_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f8";
    constant REG_RB_READOUT_CNTS_CNTS_26_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_26_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_27_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f8";
    constant REG_RB_READOUT_CNTS_CNTS_27_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_27_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_28_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f9";
    constant REG_RB_READOUT_CNTS_CNTS_28_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_28_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_29_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f9";
    constant REG_RB_READOUT_CNTS_CNTS_29_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_29_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_30_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f9";
    constant REG_RB_READOUT_CNTS_CNTS_30_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_30_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_31_ADDR    : std_logic_vector(9 downto 0) := "00" & x"f9";
    constant REG_RB_READOUT_CNTS_CNTS_31_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_31_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_32_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fa";
    constant REG_RB_READOUT_CNTS_CNTS_32_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_32_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_33_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fa";
    constant REG_RB_READOUT_CNTS_CNTS_33_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_33_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_34_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fa";
    constant REG_RB_READOUT_CNTS_CNTS_34_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_34_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_35_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fa";
    constant REG_RB_READOUT_CNTS_CNTS_35_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_35_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_36_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fb";
    constant REG_RB_READOUT_CNTS_CNTS_36_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_36_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_37_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fb";
    constant REG_RB_READOUT_CNTS_CNTS_37_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_37_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_38_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fb";
    constant REG_RB_READOUT_CNTS_CNTS_38_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_38_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_39_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fb";
    constant REG_RB_READOUT_CNTS_CNTS_39_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_39_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_40_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fc";
    constant REG_RB_READOUT_CNTS_CNTS_40_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_40_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_41_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fc";
    constant REG_RB_READOUT_CNTS_CNTS_41_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_41_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_42_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fc";
    constant REG_RB_READOUT_CNTS_CNTS_42_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_42_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_43_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fc";
    constant REG_RB_READOUT_CNTS_CNTS_43_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_43_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_44_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fd";
    constant REG_RB_READOUT_CNTS_CNTS_44_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_44_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_45_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fd";
    constant REG_RB_READOUT_CNTS_CNTS_45_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_45_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_CNTS_46_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fd";
    constant REG_RB_READOUT_CNTS_CNTS_46_MSB    : integer := 23;
    constant REG_RB_READOUT_CNTS_CNTS_46_LSB     : integer := 16;

    constant REG_RB_READOUT_CNTS_CNTS_47_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fd";
    constant REG_RB_READOUT_CNTS_CNTS_47_MSB    : integer := 31;
    constant REG_RB_READOUT_CNTS_CNTS_47_LSB     : integer := 24;

    constant REG_RB_READOUT_CNTS_CNTS_48_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fe";
    constant REG_RB_READOUT_CNTS_CNTS_48_MSB    : integer := 7;
    constant REG_RB_READOUT_CNTS_CNTS_48_LSB     : integer := 0;

    constant REG_RB_READOUT_CNTS_CNTS_49_ADDR    : std_logic_vector(9 downto 0) := "00" & x"fe";
    constant REG_RB_READOUT_CNTS_CNTS_49_MSB    : integer := 15;
    constant REG_RB_READOUT_CNTS_CNTS_49_LSB     : integer := 8;

    constant REG_RB_READOUT_CNTS_RESET_ADDR    : std_logic_vector(9 downto 0) := "00" & x"ff";
    constant REG_RB_READOUT_CNTS_RESET_BIT    : integer := 0;

    constant REG_RB_READOUT_CNTS_SNAP_ADDR    : std_logic_vector(9 downto 0) := "01" & x"00";
    constant REG_RB_READOUT_CNTS_SNAP_BIT    : integer := 0;
    constant REG_RB_READOUT_CNTS_SNAP_DEFAULT : std_logic := '1';

    constant REG_PULSER_FIRE_ADDR    : std_logic_vector(9 downto 0) := "01" & x"00";
    constant REG_PULSER_FIRE_BIT    : integer := 0;

    constant REG_PULSER_CH_0_24_ADDR    : std_logic_vector(9 downto 0) := "01" & x"01";
    constant REG_PULSER_CH_0_24_MSB    : integer := 24;
    constant REG_PULSER_CH_0_24_LSB     : integer := 0;
    constant REG_PULSER_CH_0_24_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_25_49_ADDR    : std_logic_vector(9 downto 0) := "01" & x"02";
    constant REG_PULSER_CH_25_49_MSB    : integer := 24;
    constant REG_PULSER_CH_25_49_LSB     : integer := 0;
    constant REG_PULSER_CH_25_49_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_50_74_ADDR    : std_logic_vector(9 downto 0) := "01" & x"03";
    constant REG_PULSER_CH_50_74_MSB    : integer := 24;
    constant REG_PULSER_CH_50_74_LSB     : integer := 0;
    constant REG_PULSER_CH_50_74_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_75_99_ADDR    : std_logic_vector(9 downto 0) := "01" & x"04";
    constant REG_PULSER_CH_75_99_MSB    : integer := 24;
    constant REG_PULSER_CH_75_99_LSB     : integer := 0;
    constant REG_PULSER_CH_75_99_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_100_124_ADDR    : std_logic_vector(9 downto 0) := "01" & x"05";
    constant REG_PULSER_CH_100_124_MSB    : integer := 24;
    constant REG_PULSER_CH_100_124_LSB     : integer := 0;
    constant REG_PULSER_CH_100_124_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_125_149_ADDR    : std_logic_vector(9 downto 0) := "01" & x"06";
    constant REG_PULSER_CH_125_149_MSB    : integer := 24;
    constant REG_PULSER_CH_125_149_LSB     : integer := 0;
    constant REG_PULSER_CH_125_149_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_150_174_ADDR    : std_logic_vector(9 downto 0) := "01" & x"07";
    constant REG_PULSER_CH_150_174_MSB    : integer := 24;
    constant REG_PULSER_CH_150_174_LSB     : integer := 0;
    constant REG_PULSER_CH_150_174_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_PULSER_CH_175_199_ADDR    : std_logic_vector(9 downto 0) := "01" & x"08";
    constant REG_PULSER_CH_175_199_MSB    : integer := 24;
    constant REG_PULSER_CH_175_199_LSB     : integer := 0;
    constant REG_PULSER_CH_175_199_DEFAULT : std_logic_vector(24 downto 0) := '0' & x"000000";

    constant REG_XADC_CALIBRATION_ADDR    : std_logic_vector(9 downto 0) := "01" & x"20";
    constant REG_XADC_CALIBRATION_MSB    : integer := 11;
    constant REG_XADC_CALIBRATION_LSB     : integer := 0;

    constant REG_XADC_VCCPINT_ADDR    : std_logic_vector(9 downto 0) := "01" & x"20";
    constant REG_XADC_VCCPINT_MSB    : integer := 27;
    constant REG_XADC_VCCPINT_LSB     : integer := 16;

    constant REG_XADC_VCCPAUX_ADDR    : std_logic_vector(9 downto 0) := "01" & x"21";
    constant REG_XADC_VCCPAUX_MSB    : integer := 11;
    constant REG_XADC_VCCPAUX_LSB     : integer := 0;

    constant REG_XADC_VCCODDR_ADDR    : std_logic_vector(9 downto 0) := "01" & x"21";
    constant REG_XADC_VCCODDR_MSB    : integer := 27;
    constant REG_XADC_VCCODDR_LSB     : integer := 16;

    constant REG_XADC_TEMP_ADDR    : std_logic_vector(9 downto 0) := "01" & x"22";
    constant REG_XADC_TEMP_MSB    : integer := 11;
    constant REG_XADC_TEMP_LSB     : integer := 0;

    constant REG_XADC_VCCINT_ADDR    : std_logic_vector(9 downto 0) := "01" & x"22";
    constant REG_XADC_VCCINT_MSB    : integer := 27;
    constant REG_XADC_VCCINT_LSB     : integer := 16;

    constant REG_XADC_VCCAUX_ADDR    : std_logic_vector(9 downto 0) := "01" & x"23";
    constant REG_XADC_VCCAUX_MSB    : integer := 11;
    constant REG_XADC_VCCAUX_LSB     : integer := 0;

    constant REG_XADC_VCCBRAM_ADDR    : std_logic_vector(9 downto 0) := "01" & x"23";
    constant REG_XADC_VCCBRAM_MSB    : integer := 27;
    constant REG_XADC_VCCBRAM_LSB     : integer := 16;

    constant REG_HOG_GLOBAL_DATE_ADDR    : std_logic_vector(9 downto 0) := "10" & x"00";
    constant REG_HOG_GLOBAL_DATE_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_DATE_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_TIME_ADDR    : std_logic_vector(9 downto 0) := "10" & x"01";
    constant REG_HOG_GLOBAL_TIME_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_TIME_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"02";
    constant REG_HOG_GLOBAL_VER_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_VER_LSB     : integer := 0;

    constant REG_HOG_GLOBAL_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"03";
    constant REG_HOG_GLOBAL_SHA_MSB    : integer := 31;
    constant REG_HOG_GLOBAL_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"04";
    constant REG_HOG_TOP_SHA_MSB    : integer := 31;
    constant REG_HOG_TOP_SHA_LSB     : integer := 0;

    constant REG_HOG_TOP_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"05";
    constant REG_HOG_TOP_VER_MSB    : integer := 31;
    constant REG_HOG_TOP_VER_LSB     : integer := 0;

    constant REG_HOG_HOG_SHA_ADDR    : std_logic_vector(9 downto 0) := "10" & x"06";
    constant REG_HOG_HOG_SHA_MSB    : integer := 31;
    constant REG_HOG_HOG_SHA_LSB     : integer := 0;

    constant REG_HOG_HOG_VER_ADDR    : std_logic_vector(9 downto 0) := "10" & x"07";
    constant REG_HOG_HOG_VER_MSB    : integer := 31;
    constant REG_HOG_HOG_VER_LSB     : integer := 0;


end registers;
