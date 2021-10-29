library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity iodelay is
  port(
    clock       : in  std_logic;
    data_i      : in  std_logic;
    data_o      : out std_logic;
    tap_delay_i : in  std_logic_vector (4 downto 0) := "00000"
    );
end iodelay;

architecture behavioral of iodelay is

begin

  iodelay_a7 : idelaye2
    generic map (
      CINVCTRL_SEL          => "FALSE",     -- Enable dynamic clock inversion (FALSE, TRUE)
      DELAY_SRC             => "IDATAIN",   -- Delay input (IDATAIN, DATAIN)
      HIGH_PERFORMANCE_MODE => "FALSE",     -- Reduced jitter ("TRUE"), Reduced power ("FALSE")
      IDELAY_TYPE           => "VAR_LOAD",  -- FIXED, VARIABLE, VAR_LOAD, VAR_LOAD_PIPE
      IDELAY_VALUE          => 0,           -- Input delay tap setting (0-31)
      PIPE_SEL              => "FALSE",     -- Select pipelined mode, FALSE, TRUE
      REFCLK_FREQUENCY      => 200.803,     -- IDELAYCTRL clock input frequency in MHz (190.0-210.0, 290.0-310.0).
      SIGNAL_PATTERN        => "DATA"       -- DATA, CLOCK input signal
      )
    port map (
      CNTVALUEOUT => open,                  -- 5-bit output: Counter value output
      DATAOUT     => data_o,                -- 1-bit output: Delayed data output
      C           => clock,                 -- 1-bit input: Clock input
      CE          => '0',                   -- 1-bit input: Active high enable increment/decrement input
      CINVCTRL    => '0',                   -- 1-bit input: Dynamic clock inversion input
      CNTVALUEIN  => tap_delay_i,           -- 5-bit input: Counter value input
      DATAIN      => '0',                   -- 1-bit input: Internal delay data input
      IDATAIN     => data_i,                -- 1-bit input: Data input from the I/O
      INC         => '0',                   -- 1-bit input: Increment / Decrement tap delay input
      LD          => '1',                   -- 1-bit input: Load IDELAY_VALUE input
      LDPIPEEN    => '0',                   -- 1-bit input: Enable PIPELINE register to load data input
      REGRST      => '1'                    -- 1-bit input: Active-high reset tap-delay input
      );

end behavioral;
