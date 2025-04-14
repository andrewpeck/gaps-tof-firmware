-- Copyright 2025 Andrew Peck

-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met:

-- 1. Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.

-- 2. Redistributions in binary form must reproduce the above copyright notice,
-- this list of conditions and the following disclaimer in the documentation
-- and/or other materials provided with the distribution.

-- 3. Neither the name of the copyright holder nor the names of its contributors
-- may be used to endorse or promote products derived from this software without
-- specific prior written permission.

-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
-- ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity prescale is
  generic (
    SEED : integer := 0
    );
  port(
    clk     : in  std_logic;
    rst     : in  std_logic;
    en      : in  std_logic;
    setting : in  std_logic_vector (31 downto 0);
    din     : in  std_logic;
    accept  : out std_logic;
    drop    : out std_logic
    );
end;

architecture rtl of prescale is

  signal din_oneshot : std_logic;
  signal urandom     : std_logic_vector (31 downto 0);
  signal enable      : std_logic;

begin

  oneshot_gaps_trigger_blocked : entity work.oneshot
    port map (
      clk => clk,
      d   => en and din,
      q   => din_oneshot
      );

  urand_inf_track_central : entity work.urand_inf
    generic map (SEED => seed)
    port map (
      clk   => clk,
      rst_n => not rst,
      u     => urandom
      );

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (setting /= x"00000000" and setting >= urandom) then
        enable <= '1';
      else
        enable <= '0';
      end if;
    end if;
  end process;

  accept <= din_oneshot and enable;
  drop   <= din_oneshot and not enable;

end rtl;
