
-- https://docs.xilinx.com/v/u/en-US/ug472_7Series_Clocking
--
-- The variable phase shift is controlled by the PSEN, PSINCDEC, PSCLK, and
-- PSDONE ports (Figure 3-7).
--
-- After the MMCM locks, the initial phase is determined by the CLKOUT_PHASE
-- attribute. Most commonly, no initial phase shift is selected.
--
-- The phase of the MMCM output clock(s) increments/decrements according to the
-- interaction of PSEN, PSINCDEC, PSCLK, and PSDONE from the initial or
-- previously performed dynamic phase shift. PSEN, PSINCDEC, and PSDONE are
-- synchronous to PSCLK.
--
-- When PSEN is asserted for one PSCLK clock period, a phase-shift
-- increment/decrement is initiated. When PSINCDEC is High, an increment is
-- initiated and when PSINCDEC is Low, a decrement is initiated.
--
-- Each increment adds to the phase shift of the MMCM clock outputs by 1/56th of
-- the VCO period. Similarly, each decrement decreases the phase shift by 1/56th
-- of the VCO period.
--
-- PSEN must be active for one PSCLK period. PSDONE is High for exactly one
-- clock period when the phase shift is complete. The number of PSCLK cycles is
-- deterministic and is always 12 PSCLK cycles.
--
-- After initiating the phase shift by asserting PSEN, the MMCM output clocks
-- move from their original phase shift to an increment/ decrement phase shift.
-- The completion of the increment or decrement is signaled when PSDONE asserts
-- High.
--
-- After PSDONE has pulsed High, another increment/decrement can be initiated.
-- There is no maximum phase shift or phase-shift overflow. An entire clock
-- period (360 degrees) can always be phase shifted regardless of frequency.
-- When the end of the period is reached, the phase shift wraps around
-- round-robin style.


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- VCO freq = 990 MHz = 1.01 ns
entity phase_shifter is
  generic(
    SHIFT_BITS : integer := 12
    );
  port(
    clock        : in std_logic;
    shifts_to_do : in std_logic_vector (SHIFT_BITS-1 downto 0);
    enable       : in std_logic;

    psen     : out std_logic;
    psdone   : in  std_logic;

    done : out std_logic
    );
end phase_shifter;

architecture behavioral of phase_shifter is

  signal shifts_left  : natural range 0 to 2**SHIFT_BITS-1 := 0;    --
  signal enable_ff    : std_logic                          := '0';  -- copy the enable input so we can be rising edge sensitive
  signal start_shift  : std_logic                          := '0';  -- pulsed signal to start a new shift

  constant WAIT_MAX   : natural                     := 15;
  signal wait_counter : natural range 0 to WAIT_MAX := 0;  -- only perform a shift every ~16 clock cycles

begin

  done <= '1' when shifts_left = 0 else '0';

  -- make the input rising edge sensitive
  process (clock) is
  begin
    if (rising_edge(clock)) then
      enable_ff <= enable;
      if (enable_ff = '0' and enable = '1') then
        start_shift <= '1';
      else
        start_shift <= '0';
      end if;

    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then

      psen     <= '0';

      -- starting a new shift, copy the input into a counter
      if (start_shift = '1' and shifts_left /= 0) then

        shifts_left <= to_integer(unsigned(shifts_to_do));

      -- while we still have shifts to do...
      elsif (shifts_left > 0) then

        -- shifting takes 12 clock cycles so only shift every so often
        if (wait_counter = 0) then
          psen         <= '1';
          shifts_left  <= shifts_left - 1;
          wait_counter <= WAIT_MAX;
        else
          wait_counter <= wait_counter - 1;
        end if;

      end if;


    end if;
  end process;

end behavioral;
