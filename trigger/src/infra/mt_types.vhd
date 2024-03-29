library work;
use work.constants.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package mt_types is

  type ip_addr_t is array (integer range 3 downto 0) of integer range 0 to 255;
  function to_slv (addr : ip_addr_t) return std_logic_vector;

  --------------------------------------------------------------------------------
  -- channel data / trigger data
  --------------------------------------------------------------------------------

  -- flat container to hold discriminator levels
  type threshold_array_t is
    array(TOT_LT_CHANNELS-1 downto 0) of std_logic_vector(1 downto 0);

  -- flat container to hold binary hit info
  subtype channel_bitmask_t is
    std_logic_vector (TOT_LT_CHANNELS-1 downto 0);

  -- container to hold binary hit info per RB or per LT
  type lt_bitmask_t is
    array(NUM_LTS-1 downto 0) of std_logic_vector(NUM_LT_BITS-1 downto 0);

  --------------------------------------------------------------------------------
  -- coarse delay
  --------------------------------------------------------------------------------

  -- type for coarse (integer clock cycle) delays
  subtype coarse_delay_t is std_logic_vector (3 downto 0);

  type lt_coarse_delays_array_t
    is array (integer range 0 to NUM_LT_MT_PRI-1) of coarse_delay_t;

end package mt_types;

package body mt_types is

  -- function reshape (arr : channel_array_t) return rb_channel_array_t is
  --   variable result: rb_channel_array_t;
  -- begin
  --   for I in 0 to result'length-1 loop
  --     result(I) := arr((I+1)*NUM_RB_CHANNELS-1 downto NUM_RB_CHANNELS*I);
  --   end loop;
  --   return result;
  -- end function;

  -- function reshape (arr : channel_array_t) return lt_channel_array_t is
  --   variable result: lt_channel_array_t;
  -- begin
  --   for I in 0 to result'length-1 loop
  --     result(I) := arr((I+1)*TOT_LT_CHANNELS-1 downto TOT_LT_CHANNELS*I);
  --   end loop;
  --   return result;
  -- end function;

  -- function reshape (arr : lt_channel_array_t) return channel_array_t is
  --   variable result: channel_array_t;
  -- begin
  --   for I in 0 to arr'length-1 loop
  --     result((I+1)*(TOT_LT_CHANNELS)-1 downto TOT_LT_CHANNELS*I) := arr(I);
  --   end loop;
  --   return result;
  -- end function;

  -- function reshape (arr : rb_channel_array_t) return channel_array_t is
  --   variable result: channel_array_t;
  -- begin
  --   for I in 0 to arr'length-1 loop
  --     result((I+1)*NUM_RB_CHANNELS-1 downto NUM_RB_CHANNELS*I) := arr(I);
  --   end loop;
  --   return result;
  -- end function;

  function to_slv (addr : ip_addr_t) return std_logic_vector is
    variable slv : std_logic_vector(31 downto 0);
  begin
    slv(31 downto 24) := std_logic_vector(to_unsigned(addr(3), 8));
    slv(23 downto 16) := std_logic_vector(to_unsigned(addr(2), 8));
    slv(15 downto 8)  := std_logic_vector(to_unsigned(addr(1), 8));
    slv(7 downto 0)   := std_logic_vector(to_unsigned(addr(0), 8));
    return slv;
  end;

end package body;
