library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity integrator is
  generic(
    MAX   : natural;
    WIDTH : natural
    );
  port(
    clk    : in  std_logic;
    trg_i  : in  std_logic;
    trg_o  : out std_logic;
    d      : in  std_logic_vector(WIDTH-1 downto 0);
    q      : out std_logic_vector(WIDTH-1 downto 0);
    window : in  natural
    );
end integrator;

architecture behavioral of integrator is
  signal count : natural range 0 to MAX := 0;
  signal reg   : std_logic_vector(WIDTH-1 downto 0);
begin

  q <= reg;

  process (clk) is
  begin
    if (rising_edge(clk)) then

      trg_o <= '0';

      if (trg_i = '1') then
        count <= window;
        reg   <= d;

        if (window=0) then
          trg_o <= '1';
        end if;

      elsif (count > 0) then
        reg   <= reg or d;
        count <= count - 1;

        if (count = 1) then
          trg_o <= '1';
        end if;

      end if;
    end if;
  end process;

end behavioral;
