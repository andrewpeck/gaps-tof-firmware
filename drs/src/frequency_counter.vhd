library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity frequency_counter is

  generic (
    clk_a_freq : natural := 31250000
    );
  port (
    reset : in  std_logic;
    clk_a : in  std_logic;
    clk_b : in  std_logic;
    rate  : out std_logic_vector(31 downto 0) := (others => '0')
    );

end entity frequency_counter;

architecture behavioral of frequency_counter is
  signal pulse, pulse_synced, pulse_synced_last : std_logic := '0';
  signal valid                                  : std_logic := '0';
  signal count                                  : integer   := 0;
  signal count_a                                : integer   := 0;
  signal count_b                                : integer   := 0;
begin

  -- produce a pulse every one second
  process (clk_a) is
  begin
    if (rising_edge(clk_a)) then
      if (count_a = clk_a_freq) then
        count_a <= 0;
        pulse   <= '1';
      else
        count_a <= count_a + 1;
        -- keep the pulse high until we get a handshake,
        -- since we maybe be going from fast to slow clocks
        if (valid = '1') then
          pulse <= '0';
        end if;
      end if;
    end if;
  end process;

  -- count how many b clocks we get in one second of A clock, this will be the freq in Hz
  process (clk_b) is
  begin
    if (rising_edge(clk_b)) then
      -- shorten the pulse, make sure it is only 1 clock long in the B domain
      if (pulse_synced = '1' and pulse_synced_last = '0') then
        count   <= count_b;
        count_b <= 0;
      else
        count_b <= count_b + 1;
      end if;
    end if;
  end process;

  -- clock domain crossings

  process (clk_b) is
    attribute ASYNC_REG               : string;
    variable measure_sr               : std_logic_vector (3 downto 0);
    attribute ASYNC_REG of measure_sr : variable is "true";
  begin
    if (rising_edge(clk_b)) then
      measure_sr        := measure_sr(measure_sr'length-2 downto 0) & pulse;
      pulse_synced      <= measure_sr(measure_sr'length-1);
      pulse_synced_last <= pulse_synced;
    end if;
  end process;

  process (clk_a) is
    attribute ASYNC_REG             : string;
    variable valid_sr               : std_logic_vector (3 downto 0);
    attribute ASYNC_REG of valid_sr : variable is "true";
  begin
    if (rising_edge(clk_a)) then
      valid_sr := valid_sr(valid_sr'length-2 downto 0) & pulse_synced;
      valid    <= valid_sr(valid_sr'length-1);
    end if;
  end process;

  -- output buffer

  process (clk_a) is
  begin
    if (rising_edge(clk_a)) then
      if valid = '1' then
        rate <= std_logic_vector(to_unsigned(count, rate'length));
      end if;
    end if;
  end process;

end architecture behavioral;
