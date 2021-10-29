library work;
use work.constants.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package mt_types is

  --------------------------------------------------------------------------------
  -- channel data / trigger data
  --------------------------------------------------------------------------------

  type channel_array_t is array (integer range NUM_RBS-1 downto 0) of
    std_logic_vector(15 downto 0);

  --------------------------------------------------------------------------------
  -- coarse delay
  --------------------------------------------------------------------------------

  subtype coarse_delay_t is std_logic_vector (3 downto 0);

  -- coarse delays x 4
  type lt_coarse_delays_t is array (integer range 0 to NUM_LT_MT_LINKS-1) of
    coarse_delay_t;

  -- coarse delays x 20 x 4
  type lt_coarse_delays_array_t is array (integer range 0 to NUM_LTS-1) of
    lt_coarse_delays_t;

  --------------------------------------------------------------------------------
  -- Fine delays
  --------------------------------------------------------------------------------

  subtype tap_delay_t is std_logic_vector (4 downto 0);

  -- clock delays x 20
  type lt_clk_delays_array_t is array (integer range 0 to NUM_LTS-1) of
    tap_delay_t;

  -- data delays x 4
  type lt_data_fine_delays_t is array (integer range 0 to NUM_LT_MT_LINKS-1) of
    tap_delay_t;

  -- data delays x 20 x 4
  type lt_data_fine_delays_array_t is array (integer range 0 to NUM_LTS-1) of
    lt_data_fine_delays_t;

end package mt_types;
