--------------------------------------------------------------------------------
-- decoder

-- assumes a decode clock at 8 times the incoming clock rate
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity manchester_decoder is
  port(
    clk  : in  std_logic;
    din  : in  std_logic;
    dout : out std_logic := '0';
    dav  : out std_logic := '0'
    );
end manchester_decoder;

architecture rtl of manchester_decoder is
  signal Q0, Q1, Q2, Q3, Q4 : std_logic := '0';
  signal strb               : std_logic := '0';
begin

  process (clk) is
  begin
    if (rising_edge(clk)) then
      Q0 <= din;
      Q1 <= not Q0;
      Q2 <= (Q2 or ((not Q1) xor Q0)) and not Q4;
      Q3 <= Q2;
      Q4 <= Q3 and (Q2 or Q4);

      if (strb = '1') then
        dout <= Q1;
      end if;

      dav <= strb;

    end if;
  end process;

  strb <= not Q2 and not Q4 and ((not Q1) xor Q0);

end rtl;
