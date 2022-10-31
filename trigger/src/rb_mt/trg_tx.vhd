----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- Trigger Rx
----------------------------------------------------------------------------------
-- Serializes a trigger link from MT to RB
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity trg_tx is
  generic(
    EVENTCNTB  : natural := 32;
    MASKCNTB   : natural := 8;
    MANCHESTER : boolean := true
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic;

    trg_i : in std_logic;

    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0);
    ch_mask_i   : in std_logic_vector (MASKCNTB-1 downto 0)

    );
end trg_tx;

architecture rtl of trg_tx is

  constant LENGTH : natural := EVENTCNTB + MASKCNTB + 1;

  type state_t is (IDLE_state, DATA_state);
  signal state         : state_t   := IDLE_state;
  signal state_bit_cnt : natural   := 0;
  signal trg           : std_logic := '0';

  signal packet_buf : std_logic_vector (LENGTH-1 downto 0) := (others => '0');

  signal serial_data : std_logic := '0';

begin

  process (clock)
  begin

    if (rising_edge(clock)) then

      serial_data <= '0';
      case state is

        when IDLE_state =>

          if (trg_i = '1') then
            serial_data <= '1';
            state       <= DATA_state;
            packet_buf  <= or_reduce(ch_mask_i) & ch_mask_i & event_cnt_i;
          end if;

        when DATA_state =>

          if (state_bit_cnt = LENGTH - 1) then
            state         <= IDLE_state;
            state_bit_cnt <= 0;
          else
            state_bit_cnt <= state_bit_cnt + 1;
          end if;

          serial_data <= packet_buf(LENGTH-1-state_bit_cnt);

      end case;

      if (reset = '1') then
        state       <= IDLE_state;
        serial_data <= '0';
      end if;

    end if;
  end process;

  gen_manchester : if (MANCHESTER) generate
    serial_o <= serial_data xor clock;
  end generate;

  gen_nomanchester : if (not MANCHESTER) generate
    serial_o <= serial_data;
  end generate;

end rtl;
