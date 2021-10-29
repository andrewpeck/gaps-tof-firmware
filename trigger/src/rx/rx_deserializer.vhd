
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity rx_deserializer is
  generic(
    NCH       : integer := 4;
    WORD_SIZE : integer := 16
    );
  port(

    clock  : in std_logic;
    data_i : in std_logic_vector (NCH-1 downto 0);
    data_o : in std_logic_vector (WORD_SIZE-1 downto 0)
    );
end rx_deserializer;

architecture behavioral of rx_deserializer is

  signal data_buf : std_logic_vector (WORD_SIZE+1-1 downto 0) := (others => '0');

  type rx_state_t is (IDLE, RX);
  signal rx_state : rx_state_t := IDLE;

  constant MAX_WORDS : integer := integer(ceil(real((WORD_SIZE+1)/NCH)));

  signal word_cnt : integer range 0 to MAX_WORDS-1 := 0;

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then

      data_buf((word_cnt+1)*NCH-1 downto word_cnt*NCH) <= data_i;

      word_cnt <= word_cnt+1;

      case state is


        when IDLE =>

          if (data_i(0) = '1') then
            state <= RX;
          else
            word_cnt <= 0;
          end if;

        when RX =>

          if (word_cnt = MAX_WORDS-1) then
            state    <= IDLE;
            data_o   <= data(data_o'length downto 1);
            word_cnt <= 0;
          end if;

      end case;

    end if;
  end process;

end behavioral;
