
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity rb_deadtime is
  generic(
    NUM_RBS    : natural;
    CLK_PERIOD : real := 10.0
    );
  port(
    clock     : in  std_logic;
    trg_i     : in  std_logic;
    ch_mask_i : in  std_logic_vector (NUM_RBS*8-1 downto 0);
    dead_o    : out std_logic_vector (NUM_RBS-1 downto 0)
    );
end rb_deadtime;

architecture behavioral of rb_deadtime is

  constant RB_CLK_PERIOD        : real    := 30.0;

  -- 1024 clocks for the ADC data + a few clocks for latency + switching
  constant DEADTIME_PER_CHANNEL : natural := integer(ceil(1034.0 * RB_CLK_PERIOD / CLK_PERIOD));

  -- this should be programmed to the constant deadtime of a readout board
  -- including wait_vdd etc.
  -- 105      clocks for START_RUNNING
  -- 110      clocks for WAIT_VDD
  -- 1        clocks for INIT_READOUT
  -- 1        clocks for RSR_LOAD
  -- 1        clocks for STOP_CELL
  -- 1        clocks for DONE
  -- 10       clocks for safety factor, transmission, serialization
  -- 1024 x N clocks for DATA
  constant CONSTANT_DEADTIME : natural := integer(ceil(229.0 * RB_CLK_PERIOD / CLK_PERIOD));

  constant DEADMAX : natural := 9*DEADTIME_PER_CHANNEL + CONSTANT_DEADTIME;

  type dead_cnt_array_t is array (integer range <>) of integer range 0 to DEADMAX;

  signal dead_cnt : dead_cnt_array_t (NUM_RBS-1 downto 0);

  function count_ones(slv : std_logic_vector) return natural is
    variable n_ones : natural := 0;
  begin
    for i in slv'range loop
      if slv(i) = '1' then
        n_ones := n_ones + 1;
      end if;
    end loop;
    return n_ones;
  end function count_ones;

  function calc_deadtime (const : natural; per_channel : natural; mask : std_logic_vector (7 downto 0)) return natural is
  begin
    return const + per_channel*count_ones(mask);
  end;

begin

  rbgen : for I in 0 to NUM_RBS-1 generate
  begin
    process (clock) is
    begin
      if (rising_edge(clock)) then
        if (dead_o(I) = '0' and trg_i = '1') then
          dead_cnt(I) <= calc_deadtime(CONSTANT_DEADTIME, DEADTIME_PER_CHANNEL, ch_mask_i(8*(I+1)-1 downto 8*I));
          dead_o(I)     <= '1';
        elsif (dead_cnt(I) > 0) then
          dead_o(I)     <= '1';
          dead_cnt(I) <= dead_cnt(I)-1;
        else
          dead_o(I) <= '0';
        end if;
      end if;
    end process;


  end generate;


end behavioral;
