library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity majority is
generic (
  g_NUM_BITS : integer := 1
);
port(
  a : in  std_logic_vector (g_NUM_BITS-1 downto 0);
  b : in  std_logic_vector (g_NUM_BITS-1 downto 0);
  c : in  std_logic_vector (g_NUM_BITS-1 downto 0);
  y : out std_logic_vector (g_NUM_BITS-1 downto 0)
);
end majority;

architecture behavioral of majority is

begin

  y <= (a and b) or (b and c) or (a and c);

end behavioral;

