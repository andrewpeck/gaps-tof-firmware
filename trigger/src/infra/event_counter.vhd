library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;
use work.constants.all;

entity event_counter is
  port(

    clk              : in  std_logic;
    rst_i            : in  std_logic;
    global_trigger_i : in  std_logic;
    --trigger_i        : in  channel_array_t;
    event_count_o    : out std_logic_vector (EVENTCNTB-1 downto 0)
    );
end event_counter;

architecture behavioral of event_counter is

  signal event_count       : unsigned (EVENTCNTB-1 downto 0) := (others => '0');
  constant event_count_max : unsigned (EVENTCNTB-1 downto 0) := (others => '1');

begin

  event_count_o <= std_logic_vector(event_count);

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (rst_i = '1') then
        event_count <= (others => '0');
      -- increment
      elsif (event_count /= event_count_max and global_trigger_i = '1') then
        event_count <= event_count + 1;
      else
        event_count <= event_count;
      end if;
    end if;
  end process;

end behavioral;
