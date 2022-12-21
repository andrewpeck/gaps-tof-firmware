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
    DIV         : natural   := 50;  -- for 1 MHz @ 100 MHz clock use 100MHz / (2*1MHz)
    IDLE_LEVEL  : std_logic := '0';
    STOP_LEVEL  : std_logic := '1';
    START_LEVEL : std_logic := '1';
    MSB_FIRST   : boolean   := true
    );
  port(

    clock    : in  std_logic;
    reset    : in  std_logic;
    serial_o : out std_logic;
    busy_o   : out std_logic;

    trg_i       : in std_logic;
    event_cnt_i : in std_logic_vector (EVENTCNTB-1 downto 0)

    );
end tiu_tx;

architecture rtl of tiu_tx is

  signal clk_cnt   : natural range 0 to DIV-1 := 0;
  signal div_pulse : std_logic                := '0';

  constant LENGTH : natural := 2 + EVENTCNTB;

  type state_t is (IDLE_state, DATA_state, STOP_state);
  signal state         : state_t                     := IDLE_state;
  signal state_bit_cnt : natural range 0 to LENGTH-1 := 0;

  signal packet_buf : std_logic_vector (LENGTH-1 downto 0) := (others => '0');

  function reverse_vector (a : std_logic_vector)
    return std_logic_vector is
    variable result : std_logic_vector(a'range);
    alias aa        : std_logic_vector(a'reverse_range) is a;
  begin
    for i in aa'range loop
      result(i) := aa(i);
    end loop;
    return result;
  end;  -- function reverse_vector

  signal event_cnt : std_logic_vector (EVENTCNTB-1 downto 0);

begin

  rev : if (MSB_FIRST) generate
    event_cnt <= reverse_vector(event_cnt_i);
  end generate;
  norev : if (not MSB_FIRST) generate
    event_cnt <= event_cnt_i;
  end generate;

  busy_o <= '1' when STATE /= IDLE_state else '0';

  process (clock, reset)
  begin

    if (reset = '1') then

      state    <= IDLE_state;
      serial_o <= IDLE_LEVEL;

    elsif (rising_edge(clock)) then

      case state is

        when IDLE_state =>

          state_bit_cnt <= 0;
          serial_o      <= IDLE_LEVEL;

          if (trg_i = '1') then
            state      <= DATA_state;
            packet_buf <= STOP_LEVEL & event_cnt & START_LEVEL;
          end if;

        when DATA_state =>

          if (div_pulse = '1') then

            if (state_bit_cnt = LENGTH-1) then
              state <= STOP_state;
            else
              state_bit_cnt <= state_bit_cnt + 1;
            end if;

            serial_o <= packet_buf(state_bit_cnt);

          end if;

        -- give 1 extra cycle so the STOP bit doesn't get truncated
        when STOP_state =>

          serial_o <= STOP_LEVEL;

          if (div_pulse = '1') then
            state <= IDLE_state;
          end if;

      end case;


    end if;
  end process;

  div_pulse <= '1' when clk_cnt = 0 else '0';

  -- synchronize the clock divider to the trigger signal to avoid time smearing
  -- from 100 to 1 MHz conversion
  process (clock) is
  begin
    if (rising_edge(clock)) then

      if (clk_cnt = DIV-1 or (state = IDLE_state and trg_i = '1')) then
        clk_cnt <= 0;
      else
        clk_cnt <= clk_cnt + 1;
      end if;

      if (reset = '1') then
        clk_cnt <= 0;
      end if;

    end if;
  end process;

end rtl;
