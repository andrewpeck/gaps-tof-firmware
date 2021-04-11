library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity dtap is
  generic(
    WIDTH : positive := 32;
    MHZ   : positive := 33333333
    );
  port(

    clock      : in  std_logic;
    drs_dtap_i : in  std_logic;
    dtap_cnt_o : out std_logic_vector (WIDTH-1 downto 0)

    );
end dtap;

architecture behavioral of dtap is

  signal dtap_rising   : std_logic                     := '0';
  signal dtap_debounce : std_logic_vector (1 downto 0) := (others => '0');
  signal dtap          : std_logic                     := '0';
  signal dtap_last     : std_logic                     := '0';
  signal sec_cnt       : natural range 0 to MHZ        := 0;
  signal dtap_cnt      : natural range 0 to MHZ        := 0;
  signal dtap_cnt_reg  : natural range 0 to MHZ        := 0;


begin

  dtap_cnt_o <= std_logic_vector(to_unsigned(dtap_cnt_reg, WIDTH));

  process (clock)
  begin

    if (rising_edge(clock)) then

      dtap_debounce <= dtap_debounce (dtap_debounce'length-2 downto 0) & drs_dtap_i;

      dtap <= and_reduce(dtap_debounce);

      dtap_last <= dtap;

      if (dtap = '1' and dtap_last = '0') then
        dtap_rising <= '1';
      else
        dtap_rising <= '0';
      end if;

      if (dtap_rising = '1') then
        dtap_cnt <= dtap_cnt + 1;
      end if;

      if (sec_cnt = MHZ) then
        sec_cnt  <= 0;
        dtap_cnt <= 0;

        -- copy to stable register
        dtap_cnt_reg <= dtap_cnt;
      else
        sec_cnt <= sec_cnt + 1;
      end if;

    end if;
  end process;

end behavioral;
