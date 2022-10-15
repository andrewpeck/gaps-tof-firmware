library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clocking is
  generic (
    NUM_DSI : natural := 5
    );
  port(
    clk_p : in std_logic;
    clk_n : in std_logic;

    lvs_sync : out std_logic_vector(NUM_DSI-1 downto 0);
    ccb_sync : out std_logic;

    clk100    : out std_logic;
    clk200    : out std_logic;
    clk125    : out std_logic;
    clk125_90 : out std_logic;
    locked    : out std_logic
    );
end clocking;

architecture structural of clocking is

  component mt_clk_wiz
    port (
      -- Clock out ports
      clk100    : out std_logic;
      clk200    : out std_logic;
      clk125    : out std_logic;
      clk125_90 : out std_logic;
      -- Status and control signals
      reset     : in  std_logic;
      locked    : out std_logic;
      -- Clock in ports
      clk_in1   : in  std_logic
      );
  end component;

  signal clk_i, clk_i_bufg : std_logic := '0';

  constant DIV   : natural                  := 100;
  signal clk_cnt : natural range 0 to DIV-1 := 0;
  signal div_clk : std_logic                := '0';

begin

  process (clk100) is
  begin
    if (rising_edge(clk100)) then

      if (clk_cnt = DIV-1) then
        clk_cnt <= 0;
      else
        clk_cnt <= clk_cnt + 1;
      end if;

      if (clk_cnt < DIV/2) then
        div_clk <= '0';
      else
        div_clk <= '1';
      end if;

    end if;
  end process;

  lvs_sync <= (others => div_clk);
  ccb_sync <= div_clk;

  osc_ibuf : IBUFDS
    port map(
      i  => clk_p,
      ib => clk_n,
      o  => clk_i
      );

   BUFG_inst : BUFG
   port map (
      O => clk_i_bufg, -- 1-bit output: Clock output.
      I => clk_i  -- 1-bit input: Clock input.
   );

  clocking : mt_clk_wiz
    port map (
      -- Clock out ports
      clk100    => clk100,
      clk200    => clk200,
      clk125    => clk125,
      clk125_90 => clk125_90,
      -- Status and control signals
      reset     => '0',
      locked    => locked,
      -- Clock in ports
      clk_in1   => clk_i_bufg
      );

end structural;