library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;

entity lt_rx is
  generic(
    DIFFERENTIAL_DATA  : boolean  := false;
    DIFFERENTIAL_CLOCK : boolean  := false;
    NUM_LT_CHANNELS    : positive := 2
    );
  port(
    clk : in std_logic;

    --clk_delay   : in lt_clk_delays_array_t;
    coarse_delays : in lt_coarse_delays_t;
    posnegs       : in std_logic_vector(NUM_LT_CHANNELS-1 downto 0);
    fine_delays   : in lt_fine_delays_t;

    clk200   : in  std_logic;
    --clock_i_p : in  std_logic;
    --clock_i_n : in  std_logic;
    data_i_p : in  std_logic_vector(NUM_LT_CHANNELS-1 downto 0);
    data_i_n : in  std_logic_vector(NUM_LT_CHANNELS-1 downto 0);
    data_o   : out std_logic_vector(NUM_LT_CHANNELS-1 downto 0)

    );
end lt_rx;

architecture behavioral of lt_rx is

  function if_then_else (bool : boolean;
                         a    : string;
                         b    : string)
    return string is
  begin
    if (bool) then return a;
    else return b;
    end if;
  end if_then_else;

  signal data_i, data_idelay, data_pos,
    data_neg, data_r, data_ibuf :
    std_logic_vector (NUM_LT_CHANNELS-1 downto 0)
    := (others => '0');

  type srl_array_t is array (integer range <>) of std_logic_vector(15 downto 0);
  signal data_srls : srl_array_t (NUM_LT_CHANNELS-1 downto 0);

begin

  --------------------------------------------------------------------------------
  -- RX Data
  --
  -- IBUFDS → IDELAY → FF
  --------------------------------------------------------------------------------

  rx_gen : for I in 0 to NUM_LT_CHANNELS-1 generate
  begin

    diff_gen : if (DIFFERENTIAL_DATA) generate
      ibufdata : IBUFDS
        generic map (                   --
          DIFF_TERM    => true,         -- Differential Termination
          IBUF_LOW_PWR => true          -- Low power="TRUE", Highest performance="FALSE"
          )
        port map (
          O  => data_ibuf(I),
          I  => data_i_p(I),
          IB => data_i_n(I)
          );
    end generate;

    single_ended_gen : if (not DIFFERENTIAL_DATA) generate
      IBUF_inst : IBUF
        generic map (
          IBUF_LOW_PWR => true,         -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
          IOSTANDARD   => "DEFAULT")
        port map (
          O => data_ibuf(I),            -- Buffer output
          I => data_i_p(I)              -- Buffer input (connect directly to top-level port)
          );
    end generate;

    idelay_inst : entity work.idelay
      generic map (PATTERN => "DATA")
      port map (
        clock => clk200,
        taps  => fine_delays(I),
        din   => data_ibuf(I),
        dout  => data_idelay(I)
        );

  end generate;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      data_pos <= data_idelay;
    end if;
    if (falling_edge(clk)) then
      data_neg <= data_idelay;
    end if;
  end process;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      for I in 0 to NUM_LT_CHANNELS-1 loop
        if (posnegs(I) = '0') then
          data_r <= data_pos;
        else
          data_r <= data_neg;
        end if;
      end loop;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- coarse delays
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      for CH in 0 to NUM_LT_CHANNELS-1 loop

        --------------------------------------------------------------------------------
        -- shift register
        --------------------------------------------------------------------------------

        data_srls(CH)(0) <= data_r(CH);
        for SR in 1 to 15 loop
          data_srls(CH)(SR) <= data_srls(CH)(SR-1);
        end loop;

        --------------------------------------------------------------------------------
        -- output mux
        --------------------------------------------------------------------------------

        if (to_integer(unsigned(coarse_delays(CH))) = 0) then
          data_o(CH) <= data_r(CH);
        else
          data_o(CH) <= data_srls(CH)
                        (to_integer(unsigned(coarse_delays(CH))-1));
        end if;

      end loop;
    end if;
  end process;

end behavioral;
