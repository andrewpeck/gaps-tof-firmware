library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package types_pkg is

  function to_slv (int : integer; len : integer)
    return std_logic_vector;

  function to_int (slv : std_logic_vector)
    return integer;

  function to_int (sl : std_logic)
    return integer;

  function to_bool (sl : std_logic)
    return boolean;

  function count_ones(slv : std_logic_vector)
    return natural;

  function if_then_else (bool : boolean; a : std_logic; b : std_logic)
    return std_logic;

  function to_sl (int : integer)
    return std_logic;
 
  function shift_left (data : std_logic; shift : integer; size : integer)
    return std_logic_vector;

  --============--
  --== Common ==--
  --============--

  type int_array_t is array(integer range <>) of integer;

  type t_std2_array is array(integer range <>) of std_logic_vector(1 downto 0);
  type t_std3_array is array(integer range <>) of std_logic_vector(2 downto 0);
  type t_std4_array is array(integer range <>) of std_logic_vector(3 downto 0);
  type t_std5_array is array(integer range <>) of std_logic_vector(4 downto 0);
  type t_std8_array is array(integer range <>) of std_logic_vector(7 downto 0);
  type t_std16_array is array(integer range <>) of std_logic_vector(15 downto 0);
  type t_std32_array is array(integer range <>) of std_logic_vector(31 downto 0);
  type t_std64_array is array(integer range <>) of std_logic_vector(63 downto 0);

  --type std_array_t is array(integer range <>) of std_logic;
  --type t_std_array is array(integer range <>) of std_logic;

  type u24_array_t is array(integer range <>) of unsigned(23 downto 0);
  type u32_array_t is array(integer range <>) of unsigned(31 downto 0);

end types_pkg;

package body types_pkg is

  function to_sl (int : integer)
    return std_logic is
    variable v : std_logic;
  begin
    if (int > 0) then
      return '1';
    else
      return '0';
    end if;
  end function;

  function to_slv (int : integer; len : integer)
    return std_logic_vector is
    variable v : std_logic_vector (len-1 downto 0);
  begin
    return (std_logic_vector(to_unsigned(int, len)));
  end function;

  function to_int (slv : std_logic_vector)
    return integer is
  begin
    return (to_integer(unsigned(slv)));
  end function;

  function to_bool (sl : std_logic)
    return boolean is
  begin
    if (sl = '1') then
      return true;
    else
      return false;
    end if;

  end function;

  function to_int (sl : std_logic)
    return integer is
  begin
    return (to_integer(unsigned'('0' & sl)));
  end function;

  function count_ones(slv : std_logic_vector) return natural is
    variable n_ones : natural := 0;
  begin
    for i in slv'range loop
      if slv(i) = '1' then
        n_ones := n_ones + 1;
      end if;
    end loop;
    return n_ones;
  end function count_ones;

  function shift_left (data : std_logic; shift : integer; size : integer) return std_logic_vector is
    variable mask : std_logic_vector (size-1 downto 0) := (others => '0');
  begin
    mask(shift) := '1';
    return mask;
  end function shift_left;

  function if_then_else (bool : boolean; a : std_logic; b : std_logic) return std_logic is
  begin
    if (bool) then
      return a;
    else
      return b;
    end if;
  end if_then_else;


end package body;
