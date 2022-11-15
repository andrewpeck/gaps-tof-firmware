----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- ODELAY
----------------------------------------------------------------------------------
-- Wrapper around a 7 series ODELAYE2 element
----------------------------------------------------------------------------------

library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity odelay is
  generic(
    PATTERN : string                    -- "DATA or CLOCK"
    );
  port(
    clock : in  std_logic;
    taps  : in  std_logic_vector (4 downto 0);
    din   : in  std_logic;
    dout  : out std_logic

    );
end odelay;

architecture behavioral of odelay is

begin

  -- 78 ps per tap
  odelay_inst : odelaye2
    generic map (
      CINVCTRL_SEL          => "FALSE",     -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC             => "ODATAIN",   -- Delay input (ODATAIN, CLKIN)
      HIGH_PERFORMANCE_MODE => "FALSE",     -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      ODELAY_TYPE           => "VAR_LOAD",  -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      ODELAY_VALUE          => 0,           -- Input delay tap setting (0-31)
      PIPE_SEL              => "FALSE",     -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY      => 200.0,       -- ODELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN        => PATTERN      -- DATA, CLOCK input signal
      )
    port map (
      CNTVALUEOUT => open,                  -- 5-bit output: Counter value output
      DATAOUT     => dout,                  -- 1-bit output: Delayed data output
      C           => clock,                 -- 1-bit input: Clock input
      CE          => '0',                   -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',                   -- 1-bit input: Dynamic clock inversion input
      CLKIN       => '0',
      CNTVALUEIN  => taps,                  -- 5-bit input: Counter value input
      INC         => '0',                   -- 1-bit input: Increment / Decrement tap delay input
      LD          => '1',                   -- 1-bit input: Load ODELAY_VALUE input

      LDPIPEEN    => '0',                   -- 1-bit input: Enable PIPELINE register to load data input
      ODATAIN     => din,                   -- 1-bit input: Data input from the I/O
      REGRST      => '1'                    -- 1-bit input: Active-high reset tap-delay input
      );

end behavioral;
