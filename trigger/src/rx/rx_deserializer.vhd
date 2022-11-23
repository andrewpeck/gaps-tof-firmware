library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity rx_deserializer is
  generic(
    WORD_SIZE : positive := 8
    );
  port(
    clock   : in  std_logic;
    reset   : in  std_logic;
    data_i  : in  std_logic;
    data_o  : out std_logic_vector (WORD_SIZE-1 downto 0);
    valid_o : out std_logic;
    err_o   : out std_logic
    );
end rx_deserializer;

architecture behavioral of rx_deserializer is

  signal data_buf : std_logic_vector (WORD_SIZE-1 downto 0) := (others => '0');

  constant DEAD_TIME : integer := 4;

  type rx_state_t is (IDLE, RX, ERR_CHECK);
  signal state : rx_state_t := IDLE;

  signal state_bit_cnt : natural range 0 to WORD_SIZE - 1 := 0;

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then

      valid_o <= '0';
      err_o   <= '0';

      case state is

        when IDLE =>

          state_bit_cnt <= 0;

          if (data_i = '1') then
            state <= RX;
          end if;

        when RX =>

          if (state_bit_cnt = WORD_SIZE - 1) then
            state         <= ERR_CHECK;
            data_o        <= data_i & data_buf(WORD_SIZE-2 downto 0);
            valid_o       <= '1';
            state_bit_cnt <= 0;
          else
            data_buf(state_bit_cnt) <= data_i;
            state_bit_cnt           <= state_bit_cnt + 1;
          end if;

        when ERR_CHECK =>

          if (data_i = '1') then
            err_o  <= '1';
            data_o <= (others => '0');
          end if;

          if (state_bit_cnt = DEAD_TIME - 1) then
            state <= IDLE;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

      end case;

      if (reset = '1') then
        state <= IDLE;
      end if;

    end if;
  end process;

end behavioral;
