-- Random number generator
-- Generate 32-bit random numbers according to:
--     U = 1664525L*U(0) + 1013904223L;    (modulo 2**32)
-- just infer the DSP
--


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity urand_inf is

  generic (
    SEED : integer := 0
    );
  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    u     : out std_logic_vector(31 downto 0)
    );

end urand_inf;

architecture arch of urand_inf is

  constant k1 : unsigned(31 downto 0) := X"0019660d";
  constant k2 : unsigned(31 downto 0) := X"3c6ef35f";

  signal tu   : unsigned(31 downto 0) := to_unsigned(SEED, 32);
  signal p    : unsigned(63 downto 0) := to_unsigned(SEED, 64);
  signal mmux : unsigned(31 downto 0) := to_unsigned(SEED, 32);

  signal r_seed : std_logic := '1';

  signal reseed : std_logic := '1';

begin  -- arch

  process (clk) is
  begin
    if (rising_edge(clk)) then

      if rst_n = '0' then                 -- synchronous reset (active low)
        reseed <= '1';
      else
        r_seed <= reseed;
        p      <= mmux * k1 + k2;
        tu     <= p(31 downto 0);
        if reseed = '1' then
          reseed <= '0';
        end if;
      end if;

    end if;
  end process;

  mmux <= p(31 downto 0) when r_seed = '0'
          else unsigned(to_unsigned(SEED, 32));

  u <= std_logic_vector(tu);

end arch;
