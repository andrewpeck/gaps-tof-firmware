library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity clocking is
  port(
    clk_p : in std_logic;
    clk_n : in std_logic;

    fb_clk_p : in std_logic_vector(4 downto 0);
    fb_clk_n : in std_logic_vector(4 downto 0);

    fb_active_or : out std_logic := '0';

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

  signal clk_i : std_logic := '0';

  signal fb_clk, fb_clk_i : std_logic_vector (fb_clk_p'range) := (others => '0');
  signal fb_active        : std_logic_vector (fb_clk_p'range) := (others => '0');

begin

  osc_ibuf : IBUFDS
    port map(
      i  => clk_p,
      ib => clk_n,
      o  => clk_i
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
      clk_in1   => clk_i
      );

  fb_clk_gen : for I in fb_clk_p'range generate
  begin
    fb_clk_ibuf : IBUFDS
      port map(
        i  => fb_clk_p(I),
        ib => fb_clk_n(I),
        o  => fb_clk_i(I)
        );

    fb_clk_bufg : BUFG
      port map(
        i => fb_clk_i(I),
        o => fb_clk(I)
        );

    -- TODO: replace with frequency mons
    process (fb_clk(I)) is
    begin
      if (rising_edge(fb_clk(I))) then
        fb_active(I) <= not fb_active(I);
      end if;
    end process;

  end generate;

  fb_active_or <= xor_reduce (fb_active);

end structural;
