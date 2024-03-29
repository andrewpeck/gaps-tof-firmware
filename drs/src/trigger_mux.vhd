library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity trigger_mux is

  generic(TRIGGER_OS_MAX : natural := 3);

  port(
    clock : in std_logic;

    enable : in std_logic := '1';

    -- async trigger from scintillator
    ext_trigger_i         : in std_logic;  -- ASYNC trigger input, must be >30ns
    ext_trigger_en        : in std_logic;  -- 1 to enable external trigger
    ext_trigger_active_hi : in std_logic;  -- 1 to set ext trigger active high

    -- software trigger
    force_trig : in std_logic;

    -- master trigger
    master_trigger : in std_logic;

    -- trigger output
    dwrite_o  : out std_logic;
    trigger_o : out std_logic
    );

end trigger_mux;

architecture behavioral of trigger_mux is

  signal ext_trigger_active_hi_ff : std_logic := '0';
  signal ext_trigger_en_ff        : std_logic := '0';
  signal force_trig_ff            : std_logic := '0';

  signal ext_trigger       : std_logic := '0';
  signal ext_trigger_async : std_logic := '0';

  signal trigger_os     : std_logic                         := '0';
  signal trigger_os_cnt : natural range 0 to TRIGGER_OS_MAX := 0;

  signal trigger_r     : std_logic := '0';
  signal trigger       : std_logic := '0';
  signal trigger_dly   : std_logic := '0';

  -- put a dont touch to allow manual placement
  attribute DONT_TOUCH                       : string;
  attribute DONT_TOUCH of trigger, trigger_r : signal is "true";

begin

  process (clock) is
  begin
    if (rising_edge(clock)) then
      ext_trigger_active_hi_ff <= ext_trigger_active_hi;
      ext_trigger_en_ff        <= ext_trigger_en;
      force_trig_ff            <= force_trig;
    end if;
  end process;

  -- for accurate timing, we can't clock the external trigger input since it produces some random
  -- phase variation as the asynchronous trigger is digitized to the system clock
  --
  -- instead, the trigger input is asynchronously ANDed with the synchronous dwrite control output
  -- from the drs module.
  --
  -- a "fast" asynchronous path from trigger --> dwrite will deassert dwrite with a small,
  -- predictable delay. This delay *should* be constrained in a timing constraint to ensure some
  -- quasi-predictability
  --
  -- the logic must with minimal, and more importantly, deterministic routing delay bring the
  -- trigger input to the drs output
  --
  -- but, the trigger input must also be used to keep the dwrite input low until the digital logic
  -- takes over and keeps it de-asserted, so we need to do some rising edge detection on the
  -- signal to initiate a short oneshot (a few clock cycles)
  --
  --                      ┌───────┐       ┌───────┐       ┌───────┐       ┌────
  -- clk:                ─┘       └───────┘       └───────┘       └───────┘
  --
  --                         ┌───────────────┐
  -- ext_trigger_async   ────┘               └─────────────────────────────────
  --
  --                                      ┌───────────────┐
  -- trigger_os          ─────────────────┘               └───────────────────
  --
  --                         ┌─────────────────────────────┐
  -- ext_trigger         ────┘                             └───────────────────
  --
  --
  -- dwrite_sync          ────────────────┐
  --                                      └────────────────────
  --
  -- dwrite_async         ───┐               ┌───────
  --                         └───────────────┘
  --
  -- dwrite_out           ───┐
  --                         └──────────────────────────────────────────────────


  -- optionally invert the ext trigger input
  ext_trigger_async <= ext_trigger_i when ext_trigger_active_hi_ff = '1' else not ext_trigger_i;

  -- ext_trigger is the OR of the async and one-shotted synchronous trigger
  ext_trigger <= ext_trigger_en_ff and (ext_trigger_async);

  --
  trigger <= enable and (ext_trigger or master_trigger or force_trig_ff);

  dwrite_o <= not (trigger or trigger_os or trigger_r);

  -- rising edge only
  trigger_o <= '1' when trigger = '1' and trigger_r = '0' else '0';

  process (clock) is
  begin
    if (rising_edge(clock)) then

      trigger_r  <= trigger;

      if (trigger_r = '1') then
        trigger_os_cnt <= TRIGGER_OS_MAX;
        trigger_os     <= '1';
      else

        if (trigger_os_cnt > 0) then
          trigger_os_cnt <= trigger_os_cnt - 1;
        else
          trigger_os <= '0';
        end if;

      end if;
    end if;
  end process;

end behavioral;
