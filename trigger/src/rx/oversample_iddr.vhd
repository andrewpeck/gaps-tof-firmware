library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oversample is
  port(
    clk    : in  std_logic;
    clk90  : in  std_logic;
    data_i : in  std_logic;
    data_o : out std_logic := '0'
    );
end oversample;

architecture behavioral of oversample is

  signal d0, d90, d180, d270         : std_logic := '0';
  signal d0_r, d90_r, d180_r, d270_r : std_logic := '0';

  signal d, dd          : std_logic_vector (3 downto 0) := (others => '0');
  signal e0, e1, e2, e3 : std_logic                     := '0';

  signal sel : natural range 0 to 3 := 0;

begin

  process (clk) is
  begin
    if (rising_edge(clk)) then
      d0 <= data_i;
    end if;
    if (falling_edge(clk)) then
      d180 <= data_i;
    end if;
  end process;

  process (clk90) is
  begin
    if (rising_edge(clk90)) then
      d90 <= data_i;
    end if;
    if (falling_edge(clk90)) then
      d270 <= data_i;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      d0_r   <= d0;
      d90_r  <= d90;
      d180_r <= d180;
      d270_r <= d270;
      dd     <= d;
    end if;
  end process;

  d(3 downto 0) <= (d270_r, d180_r, d90_r, d0_r);

  e0 <= d(0) xor d(1);
  e1 <= d(1) xor d(2);
  e2 <= d(2) xor d(3);
  e3 <= d(3) xor d(0);

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if '1' = (e0 and e1) then
        sel <= 3;
      elsif '1' = (e1 and e2) then
        sel <= 0;
      elsif '1' = (e2 and e3) then
        sel <= 1;
      elsif '1' = (e3 and e0) then
        sel <= 2;
      elsif ('1' = e0) then
        sel <= 2;
      elsif ('1' = e1) then
        sel <= 3;
      elsif ('1' = e2) then
        sel <= 0;
      elsif ('1' = e3) then
        sel <= 1;
      end if;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      data_o <= dd(sel);
    end if;
  end process;

end behavioral;
