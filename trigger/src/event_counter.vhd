library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity event_counter is
  port(

    clk              : in  std_logic;
    rst              : in  std_logic;
    global_trigger_i : in  std_logic;
  --trigger_i        : in  channel_array_t;
    event_count_o    : out std_logic_vector (EVENTCNTB-1 downto 0)
    );
end event_counter;

architecture behavioral of event_counter is

  signal event_count       : unsigned (EVENTCNTB-1 downto 0) := (others => '0');
  constant event_count_max : unsigned (EVENTCNTB-1 downto 0) := (others => '1');

begin

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        event_count <= (others => '0');
      elsif (event_count /= event_count_max) then
        event_count <= event_count;
      elsif (global_trigger_i = '1') then
        event_count <= event_count + 1;
      end if;
    end if;
  end process;

end behavioral;
