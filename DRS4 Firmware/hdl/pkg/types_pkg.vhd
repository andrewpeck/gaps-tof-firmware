library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types_pkg is

    --============--
    --== Common ==--
    --============--

    type int_array_t   is array(integer range <>) of integer;
    type std_array_t   is array(integer range <>) of std_logic;
    type u24_array_t   is array(integer range <>) of unsigned(23 downto 0);
    type u32_array_t   is array(integer range <>) of unsigned(31 downto 0);
    type t_std_array   is array(integer range <>) of std_logic;
    type t_std2_array  is array(integer range <>) of std_logic_vector(1 downto 0);
    type t_std3_array  is array(integer range <>) of std_logic_vector(2 downto 0);
    type t_std4_array  is array(integer range <>) of std_logic_vector(3 downto 0);
    type t_std5_array  is array(integer range <>) of std_logic_vector(4 downto 0);
    type t_std8_array  is array(integer range <>) of std_logic_vector(7 downto 0);
    type t_std16_array is array(integer range <>) of std_logic_vector(15 downto 0);
    type t_std32_array is array(integer range <>) of std_logic_vector(31 downto 0);
    type t_std64_array is array(integer range <>) of std_logic_vector(63 downto 0);

end types_pkg;
