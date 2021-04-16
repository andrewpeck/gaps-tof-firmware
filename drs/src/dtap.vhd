library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity dtap is
  generic(
    WIDTH : positive := 16;
    MHZ   : positive := 33333333;
    DIV   : positive := 100
    );
  port(

    clock      : in  std_logic;
    drs_dtap_i : in  std_logic;
    dtap_cnt_o : out std_logic_vector (WIDTH-1 downto 0)
    );
end dtap;

architecture behavioral of dtap is

  constant MAX_CNTS : positive := MHZ/DIV;

  signal one_hz : boolean := false;

  signal dtap_rising   : std_logic                     := '0';
  signal dtap_debounce : std_logic_vector (1 downto 0) := (others => '0');
  signal dtap_r        : std_logic                     := '0';
  signal dtap_last     : std_logic                     := '0';

  signal sec_cnt      : natural range 0 to MAX_CNTS-1 := 0;
  signal dtap_cnt     : natural range 0 to MAX_CNTS-1 := 0;
  signal dtap_cnt_reg : natural range 0 to MAX_CNTS-1 := 0;

begin

  assert false report "dtap count range 0 to "
    & integer'image(DIV*(2**WIDTH-1)) & " Hz" severity note;

  dtap_cnt_o <= std_logic_vector(to_unsigned(dtap_cnt_reg, WIDTH));

  -- debounce dtap (just incase.. it is slow enough) and find the rising edge
  process (clock) is
  begin
    if (rising_edge(clock)) then
      dtap_debounce <= dtap_debounce (dtap_debounce'length-2 downto 0) & drs_dtap_i;
      dtap_r        <= and_reduce(dtap_debounce);
      dtap_last     <= dtap_r;
      if (dtap_r = '1' and dtap_last = '0') then
        dtap_rising <= '1';
      else
        dtap_rising <= '0';
      end if;
    end if;
  end process;

  -- on the rising edge of
  process (clock)
  begin
    if (rising_edge(clock)) then
      if (one_hz) then
        dtap_cnt <= 0;
      elsif (dtap_rising = '1') then
        dtap_cnt <= dtap_cnt + 1;
      end if;
    end if;
  end process;


  -- count to seconds to produce a one_hz strobe
  one_hz <= sec_cnt = MAX_CNTS-1;
  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (one_hz) then
        sec_cnt <= 0;
      else
        sec_cnt <= sec_cnt + 1;
      end if;
    end if;
  end process;

  -- copy to stable register
  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (one_hz) then
        dtap_cnt_reg <= dtap_cnt;
      end if;
    end if;
  end process;

end behavioral;
