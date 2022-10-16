library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

entity adc is
  port(

    clock : in std_logic;

    reset : in std_logic;

    calibration : out std_logic_vector(11 downto 0) := (others => '0');
    vccpint     : out std_logic_vector(11 downto 0) := (others => '0');
    vccpaux     : out std_logic_vector(11 downto 0) := (others => '0');
    vccoddr     : out std_logic_vector(11 downto 0) := (others => '0');
    temp        : out std_logic_vector(11 downto 0) := (others => '0');
    vccint      : out std_logic_vector(11 downto 0) := (others => '0');
    vccaux      : out std_logic_vector(11 downto 0) := (others => '0');
    vccbram     : out std_logic_vector(11 downto 0) := (others => '0')

    );
end adc;

architecture behavioral of adc is

  component xadc_wiz
    port (
      di_in       : in  std_logic_vector(15 downto 0);
      daddr_in    : in  std_logic_vector(6 downto 0);
      den_in      : in  std_logic;
      dwe_in      : in  std_logic;
      drdy_out    : out std_logic;
      do_out      : out std_logic_vector(15 downto 0);
      dclk_in     : in  std_logic;
      reset_in    : in  std_logic;
      vp_in       : in  std_logic;
      vn_in       : in  std_logic;
      ot_out      : out std_logic;
      channel_out : out std_logic_vector(4 downto 0);
      eoc_out     : out std_logic;
      alarm_out   : out std_logic;
      eos_out     : out std_logic;
      busy_out    : out std_logic
      );
  end component;

  signal daddr_in : std_logic_vector(6 downto 0) := (others => '0');

  signal den_in      : std_logic := '0';
  signal drdy_out    : std_logic;
  signal do_out      : std_logic_vector(15 downto 0);
  signal channel_out : std_logic_vector(4 downto 0);
  signal eoc_out     : std_logic;

begin

  xadc_wiz_inst : xadc_wiz
    port map (
      dclk_in  => clock,
      reset_in => reset,

      di_in    => (others => '0'),
      daddr_in => daddr_in,
      den_in   => den_in,
      dwe_in   => '0',
      drdy_out => drdy_out,
      do_out   => do_out,

      vp_in => '0',
      vn_in => '0',

      ot_out      => open,
      channel_out => channel_out,
      eoc_out     => eoc_out,

      alarm_out => open,
      eos_out   => open,
      busy_out  => open
      );

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (reset = '1') then
        den_in   <= '0';
        daddr_in <= (others => '0');
      else
        den_in   <= eoc_out;
        daddr_in <= "00" & channel_out;
      end if;
    end if;
  end process;

  process (clock) is
  begin
    if (rising_edge(clock)) then
      if (drdy_out = '1') then
        -- https://www.xilinx.com/support/documentation/user_guides/ug480_7Series_XADC.pdf
        --
        -- page 23 for conversions
        --
        --             ADC Code * 503.975
        -- Temp (C) = -------------------  - 273.15
        --                     4096
        --
        -- Supply          ADC Code * 3.0
        -- Voltage (V) = -------------------
        --                     4096
        --
        -- page 56 for automatic sequencing
        case to_integer(unsigned(channel_out)) is
          when 0  => temp        <= do_out(15 downto 4);
          when 1  => vccint      <= do_out(15 downto 4);
          when 2  => vccaux      <= do_out(15 downto 4);
          when 6  => vccbram     <= do_out(15 downto 4);
          when 8  => calibration <= do_out(15 downto 4);
          when 13 => vccpint     <= do_out(15 downto 4);
          when 14 => vccpaux     <= do_out(15 downto 4);
          when 15 => vccoddr     <= do_out(15 downto 4);
          when others =>
        end case;
      end if;
    end if;
  end process;


end behavioral;
