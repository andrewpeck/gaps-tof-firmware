-- Random number generator
-- Generate 32-bit random numbers according to:
--     U = 1664525L*U(0) + 1013904223L;    (modulo 2**32)
-- just infer the DSP
--


library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
--

entity urand_inf is

  port (
    clk   : in  std_logic;
    rst_n : in  std_logic;
    u     : out std_logic_vector(31 downto 0)
    );

end urand_inf;

architecture arch of urand_inf is

  constant k1 : std_logic_vector(31 downto 0) := X"0019660d";
  constant k2 : std_logic_vector(31 downto 0) := X"3c6ef35f";

  signal tu   : std_logic_vector(31 downto 0);
  signal p    : std_logic_vector(63 downto 0);
  signal seed : std_logic_vector(31 downto 0);
  signal mmux : std_logic_vector(31 downto 0);

  signal r_seed : std_logic;

  signal reseed : std_logic;

begin  -- arch

  process (clk, rst_n)
  begin  -- process
    if rst_n = '0' then                 -- asynchronous reset (active low)
      seed   <= (others => '0');
      reseed <= '1';
    elsif clk'event and clk = '1' then  -- rising clock edge
      r_seed <= reseed;
      p      <= mmux * k1 + k2;
      tu     <= p(31 downto 0);
      if reseed = '1' then
        reseed <= '0';
      end if;
    end if;

  end process;

  mmux <= p(31 downto 0) when r_seed = '0'
          else seed;

  u <= tu;

end arch;
