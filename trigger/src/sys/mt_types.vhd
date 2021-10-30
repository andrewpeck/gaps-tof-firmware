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

  -- flattened array of all channels
  subtype channel_array_t is std_logic_vector
    (NUM_RB_CHANNELS*NUM_RBS-1 downto 0);

  -- channels grouped by rb (groups of 8)
  type rb_channel_array_t is array (integer range NUM_RBS-1 downto 0) of
    std_logic_vector(NUM_RB_CHANNELS-1 downto 0);

  -- channels grouped by lt (groups of 16)
  type lt_channel_array_t is array (integer range NUM_LTS-1 downto 0) of
    std_logic_vector(NUM_LT_CHANNELS-1 downto 0);

  -- functions to convert from array representations
  function reshape (arr : channel_array_t) return rb_channel_array_t;
  function reshape (arr : channel_array_t) return lt_channel_array_t;
  function reshape (arr : rb_channel_array_t) return channel_array_t;
  function reshape (arr : lt_channel_array_t) return channel_array_t;

  --------------------------------------------------------------------------------
  -- coarse delay
  --------------------------------------------------------------------------------

  -- type for coarse (integer clock cycle) delays
  subtype coarse_delay_t is std_logic_vector (3 downto 0);

  -- coarse delays x2
  type lt_coarse_delays_t is array (integer range 0 to NUM_LT_MT_LINKS-1) of
    coarse_delay_t;

  -- coarse delays 2x20
  type lt_coarse_delays_array_t is array (integer range 0 to NUM_LTS-1) of
    lt_coarse_delays_t;

  --------------------------------------------------------------------------------
  -- Fine delays
  --------------------------------------------------------------------------------

  -- type for fine (78 ps) tape delay
  subtype tap_delay_t is std_logic_vector (4 downto 0);

  -- no more clock? :(
  -- clock delays x 20
  -- type lt_clk_delays_array_t is array (integer range 0 to NUM_LTS-1) of
  --   tap_delay_t;

  -- data delays x2
  type lt_fine_delays_t is array (integer range 0 to NUM_LT_MT_LINKS-1) of
    tap_delay_t;

  -- data delays 2x20
  type lt_fine_delays_array_t is array (integer range 0 to NUM_LTS-1) of
    lt_fine_delays_t;
end package mt_types;

package body mt_types is

  function reshape (arr : channel_array_t) return rb_channel_array_t is
    variable result: rb_channel_array_t;
  begin
    for I in 0 to result'length-1 loop
      result(I) := arr((I+1)*NUM_RB_CHANNELS-1 downto NUM_RB_CHANNELS*I);
    end loop;
    return result;
  end function;

  function reshape (arr : channel_array_t) return lt_channel_array_t is
    variable result: lt_channel_array_t;
  begin
    for I in 0 to result'length-1 loop
      result(I) := arr((I+1)*NUM_LT_CHANNELS-1 downto NUM_LT_CHANNELS*I);
    end loop;
    return result;
  end function;

  function reshape (arr : lt_channel_array_t) return channel_array_t is
    variable result: channel_array_t;
  begin
    for I in 0 to arr'length-1 loop
      result((I+1)*(NUM_LT_CHANNELS)-1 downto NUM_LT_CHANNELS*I) := arr(I);
    end loop;
    return result;
  end function;

  function reshape (arr : rb_channel_array_t) return channel_array_t is
    variable result: channel_array_t;
  begin
    for I in 0 to arr'length-1 loop
      result((I+1)*NUM_RB_CHANNELS-1 downto NUM_RB_CHANNELS*I) := arr(I);
    end loop;
    return result;
  end function;

end package body;
