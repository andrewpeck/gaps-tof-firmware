library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity oversample is
  port(
    clk    : in  std_logic;
    clk90  : in  std_logic;
    data_i : in  std_logic;
    data_o : out std_logic := '0';
    sel_o  : out std_logic_vector(1 downto 0)
    );
end oversample;

architecture behavioral of oversample is

  -- https://docs.xilinx.com/v/u/en-US/xapp1294-4x-oversampling-async-dru

  signal d0, d90, d180, d270             : std_logic := '0';
  signal d0_r, d90_r, d180_r, d270_r     : std_logic := '0';
  signal d0_rr, d90_rr, d180_rr, d270_rr : std_logic := '0';

  signal d, dd              : std_logic_vector (3 downto 0) := (others => '0');
  signal e01, e12, e23, e30 : std_logic                     := '0';

  signal sel : natural range 0 to 3 := 0;

begin

  sel_o <= std_logic_vector(to_unsigned(sel, 2));

  --------------------------------------------------------------------------------
  -- Input 4x oversampling
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      d0 <= data_i after 0.1 ns;
    end if;
    if (falling_edge(clk)) then
      d180 <= data_i after 0.1 ns;
    end if;
  end process;

  process (clk90) is
  begin
    if (rising_edge(clk90)) then
      d90 <= data_i after 0.1 ns;
    end if;
    if (falling_edge(clk90)) then
      d270 <= data_i after 0.1 ns;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- transfer from the input sampling clocks to the main 200MHz clocks
  -- clk270 goes first to 90 then to 0 to improve S&H times
  --------------------------------------------------------------------------------

  process (clk90) is
  begin
    if (rising_edge(clk90)) then
      d270_r <= d270;
    end if;
  end process;
  process (clk) is
  begin
    if (rising_edge(clk)) then
      d0_r   <= d0;
      d90_r  <= d90;
      d180_r <= d180;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      d0_rr   <= d0_r;
      d90_rr  <= d90_r;
      d180_rr <= d180_r;
      d270_rr <= d270_r;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Delay the data signals by 1 clock to align w/ selection logic
  --------------------------------------------------------------------------------

  d(3 downto 0) <= (d270_rr, d180_rr, d90_rr, d0_rr);

  process (clk) is
  begin
    if (rising_edge(clk)) then
      dd <= d;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Error Conditions
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      e01 <= d(0) xor d(1);
      e12 <= d(1) xor d(2);
      e23 <= d(2) xor d(3);
      e30 <= dd(3) xor d(0);
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      case sel is
        when 0 =>
          if (e30 = '1') then
            sel <= 1;
          elsif (e01 = '1') then
            sel <= 3;
          end if;
        when 1 =>
          if (e01 = '1') then
            sel <= 2;
          elsif (e12 = '1') then
            sel <= 0;
          end if;
        when 2 =>
          if (e12 = '1') then
            sel <= 3;
          elsif (e23 = '1') then
            sel <= 1;
          end if;
        when 3 =>
          if (e23 = '1') then
            sel <= 0;
          elsif (e30 = '1') then
            sel <= 2;
          end if;
        when others =>
          sel <= 0;
      end case;

    end if;  -- rising_edge(clk)
  end process;

  --------------------------------------------------------------------------------
  -- Output select
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      data_o <= dd(sel);
    end if;
  end process;

end behavioral;
