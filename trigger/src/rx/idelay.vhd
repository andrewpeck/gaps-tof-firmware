library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity idelay is
  generic(
    PATTERN : string                    -- "DATA or CLOCK"
    );
  port(

    clock : in  std_logic;
    taps  : in  std_logic_vector (4 downto 0);
    din   : in  std_logic;
    dout  : out std_logic

    );
end idelay;

architecture behavioral of idelay is

begin

  -- 78 ps per tap
  idelay_inst : idelaye2
    generic map (
      CINVCTRL_SEL          => "FALSE",     -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC             => "IDATAIN",   -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "FALSE",     -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE           => "VAR_LOAD",  -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE          => 0,           -- Input delay tap setting (0-31)
      PIPE_SEL              => "FALSE",     -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY      => 200.0,       -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN        => PATTERN      -- DATA, CLOCK input signal
      )
    port map (
      CNTVALUEOUT => open,                  -- 5-bit output: Counter value output
      DATAOUT     => dout,                  -- 1-bit output: Delayed data output
      C           => clock,                 -- 1-bit input: Clock input
      CE          => '0',                   -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',                   -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN  => taps,                  -- 5-bit input: Counter value input
      DATAIN      => '0',                   -- 1-bit input: Internal delay data input
      IDATAIN     => din,                   -- 1-bit input: Data input from the I/O
      INC         => '0',                   -- 1-bit input: Increment / Decrement tap delay input
      LD          => '1',                   -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN    => '0',                   -- 1-bit input: Enable PIPELINE register to load data input
      REGRST      => '1'                    -- 1-bit input: Active-high reset tap-delay input
      );

end behavioral;
