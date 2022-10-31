----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- Trigger Rx
----------------------------------------------------------------------------------
-- Serializes a trigger link from MT to TIU
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity tiu_tx is
  generic(
    EVENTCNTB   : natural   := 32;
    DIV         : natural   := 100;
    IDLE_LEVEL  : std_logic := '0';
    STOP_LEVEL  : std_logic := '1';
    START_LEVEL : std_logic := '1';
    MSB_FIRST   : boolean   := true
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic;

    trg_i       : in std_logic;
    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0)

    );
end tiu_tx;

architecture rtl of tiu_tx is

  signal clk_cnt   : natural range 0 to DIV := 0;
  signal div_pulse : std_logic              := '0';

  constant LENGTH : natural := 2 + EVENTCNTB;

  type state_t is (IDLE_state, DATA_state);
  signal state         : state_t := IDLE_state;
  signal state_bit_cnt : natural := 0;

  signal packet_buf : std_logic_vector (LENGTH-1 downto 0) := (others => '0');

  signal serial_data : std_logic := IDLE_LEVEL;

  function reverse_vector (a: std_logic_vector)
    return std_logic_vector is
    variable result: std_logic_vector(a'RANGE);
    alias aa: std_logic_vector(a'REVERSE_RANGE) is a;
  begin
    for i in aa'RANGE loop
      result(i) := aa(i);
    end loop;
    return result;
  end; -- function reverse_vector

  signal event_cnt : std_logic_vector (EVENTCNTB-1 downto 0);

begin

  rev : if (MSB_FIRST) generate
    event_cnt <= reverse_vector(event_cnt_i);
  end generate;
  norev : if (not MSB_FIRST) generate
    event_cnt <= event_cnt_i;
  end generate;

  process (clock)
  begin

    if (rising_edge(clock)) then

      serial_data <= IDLE_LEVEL;

      case state is

        when IDLE_state =>

          if (trg_i = '1') then
            state      <= DATA_state;
            packet_buf <= STOP_LEVEL & event_cnt & START_LEVEL;
          end if;

        when DATA_state =>

          if (div_pulse = '1') then

            if (state_bit_cnt = LENGTH - 1) then
              state         <= IDLE_state;
              state_bit_cnt <= 0;
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            serial_data <= packet_buf(state_bit_cnt);

          end if;

      end case;

      if (reset = '1') then
        state       <= IDLE_state;
        serial_data <= '1';
      end if;

    end if;
  end process;

  div_pulse <= '1' when clk_cnt = 0 else '0';

  -- synchronize the clock divider to the trigger signal to avoid time smearing
  -- from 100 to 1 MHz conversion
  process (clock) is
  begin
    if (rising_edge(clock)) then

      if ((state = IDLE_state and trg_i = '1') or clk_cnt = DIV-1) then
        clk_cnt <= 0;
      else
        clk_cnt <= clk_cnt + 1;
      end if;

    end if;
  end process;

end rtl;
