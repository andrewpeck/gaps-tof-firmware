library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library ieee;
use ieee.math_real.uniform;
use ieee.math_real.floor;

entity daq_tb is
end daq_tb;

architecture test of daq_tb is

  file file_RESULTS   : text;
  constant clk_period : time := 30.0 ns;
  constant sim_period : time := 40000 ns;

  signal reset : std_logic := '1';
  signal clock : std_logic := '0';

  signal debug_packet_inject_i : std_logic                      := '0';
  signal trigger_i             : std_logic                      := '0';
  signal event_cnt_i           : std_logic_vector (31 downto 0) := x"99999999";
  signal mask_i                : std_logic_vector (15 downto 0) := x"000f";
  signal board_id              : std_logic_vector (7 downto 0)  := x"77";
  signal sync_err_i            : std_logic                      := '0';
  signal dna_i                 : std_logic_vector (63 downto 0) := x"6666666666666666";
  signal hash_i                : std_logic_vector (31 downto 0) := x"CCCCCCCC";
  signal timestamp_i           : std_logic_vector (47 downto 0) := x"444444444444";
  signal roi_size_i            : std_logic_vector (9 downto 0)  := "11" & x"ff";
  signal drs_busy_i            : std_logic                      := '0';
  signal drs_data_i            : std_logic_vector (13 downto 0) := "00" & x"bbb";
  signal drs_valid_i           : std_logic                      := '1';

  signal data_o  : std_logic_vector (15 downto 0) := (others => '0');
  signal valid_o : std_logic                      := '0';
  signal busy_o  : std_logic                      := '0';

begin

  proc_clk : process
  begin
    wait for clk_period/2.0;
    clock <= '0';
    wait for clk_period/2.0;
    clock <= '1';
  end process;

  proc_reset : process
  begin
    reset <= '1';
    wait for 100 ns;
    wait until rising_edge(clock);
    reset <= '0';
    wait;
  end process;

  --proc_sim_period : process
  --begin
  --  wait for sim_period/10;
  --  report integer'image(integer(floor((100.0 * real(now / ns) / (real (sim_period / ns)))))) & "% complete";
  --end process;

  proc_finish : process
  begin
    --wait for sim_period;
    --std.env.finish;
    wait until (falling_edge(busy_o));
    wait until (valid_o='0');
    wait until (falling_edge(busy_o));
    wait until (valid_o='0');
    std.env.finish;
  end process;

  proc_inject : process
  begin
    wait for 200 ns;
    wait until rising_edge(clock);
    debug_packet_inject_i <= '1';
    wait until rising_edge(clock);
    debug_packet_inject_i <= '0';
    wait until rising_edge(clock);
    wait until busy_o = '0';

    wait for 200 ns;
    wait until rising_edge(clock);
    trigger_i <= '1';
    wait until rising_edge(clock);
    trigger_i <= '0';
    wait;
  end process;

  daq_inst : entity work.daq
    generic map (
      g_DRS_ID    => 0,
      g_WORD_SIZE => 16
      )
    port map (
      clock                 => clock,
      reset                 => reset,
      debug_packet_inject_i => debug_packet_inject_i,
      trigger_i             => trigger_i,
      event_cnt_i           => event_cnt_i,
      mask_i                => mask_i,
      board_id              => board_id,
      sync_err_i            => sync_err_i,
      dna_i                 => dna_i,
      hash_i                => hash_i,
      timestamp_i           => timestamp_i,
      roi_size_i            => roi_size_i,
      stop_cell_i           => "1111000011",
      drs_busy_i            => drs_busy_i,
      drs_data_i            => drs_data_i,
      drs_valid_i           => drs_valid_i,
      data_o                => data_o,
      valid_o               => valid_o,
      busy_o                => busy_o
      );

  fopen : process
  begin
    file_open(file_RESULTS, "daq_packet.txt", write_mode);
    wait;
  end process;

  proc_data_o : process
  begin
    wait until rising_edge(clock);
    if (valid_o = '1') then
      --assert false report "data" & integer'image(to_integer(unsigned(data_o))) severity note;
      write(file_RESULTS, "0x" & to_hstring(unsigned(data_o)) & LF);  -- Hexadecimal representation

    end if;
  end process;

end test;
