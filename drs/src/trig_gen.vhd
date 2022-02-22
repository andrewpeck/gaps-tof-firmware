-- trig_gen.vhd: generate random triggers
--
-- rate is (2^32-1)/ts   where ts is average trigger spacing in BX
--    so 1MHz = (2^32-1)/40 or x"0666_6666"
--
-- frequency = (2^32-1) * clk_period * rate
--
-- uses one DSP to create a random generator per the numerical recipes:
--     U = 1664525L*U(0) + 1013904223L;    (modulo 2**32)
--
-- the trigger output persists for one BX period
--
-- sys_rst reseeds the random generator the same way each time
-- (seed set to 0).  Could provide an external seed if desired.
--
-- NOTE:  tie sys_bx_stb to '1' to generate hits on every sys_clk

library IEEE;
use IEEE.std_logic_1164.all;

entity trig_gen is

  port (
    sys_clk    : in  std_logic;                      -- 320MHz pipeline clock
    sys_rst    : in  std_logic;                      -- active high reset
    sys_bx_stb : in  std_logic;                      -- BX strobe every 8 clocks
    rate       : in  std_logic_vector(31 downto 0);  -- rate threshold
    trig       : out std_logic);                     -- trigger out

end entity trig_gen;



architecture arch of trig_gen is

  component urand_inf is
    port (
      clk   : in  std_logic;
      rst_n : in  std_logic;
      u     : out std_logic_vector(31 downto 0));
  end component urand_inf;

  signal u     : std_logic_vector(31 downto 0);
  signal rst_n : std_logic;

begin  -- architecture arch

  rst_n <= not sys_rst;

  process (sys_clk, sys_rst) is
  begin  -- process
    if sys_rst = '1' then               -- asynchronous reset (active high)

    elsif rising_edge(sys_clk) then     -- rising clock edge

      if sys_bx_stb = '1' then
        if u < rate then
          trig <= '1';
        else
          trig <= '0';
        end if;
      end if;

    end if;
  end process;

  urand_inf_1 : entity work.urand_inf
    port map (
      clk   => sys_clk,
      rst_n => rst_n,
      u     => u);

end architecture arch;
