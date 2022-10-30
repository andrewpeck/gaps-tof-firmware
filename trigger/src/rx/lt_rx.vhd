----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- Local Trigger Receiver
----------------------------------------------------------------------------------
-- This module receives data from a single local trigger board
----------------------------------------------------------------------------------
library unisim;
use unisim.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.mt_types.all;

entity lt_rx is
  generic(
    DIFFERENTIAL_DATA : boolean := false
    );
  port(

    clk : in std_logic;

    coarse_delay : in coarse_delay_t;
    posneg       : in std_logic;
    en           : in std_logic;
    fine_delay   : in tap_delay_t;

    clk200   : in  std_logic;
    data_i_p : in  std_logic;
    data_i_n : in  std_logic;
    data_o   : out std_logic

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
    data_neg, data_r, data_ibuf : std_logic := '0';

  signal data_srl : std_logic_vector (15 downto 0);

begin

  --------------------------------------------------------------------------------
  -- RX Data
  --
  -- IBUFDS → IDELAY → FF
  --------------------------------------------------------------------------------

  diff_gen : if (DIFFERENTIAL_DATA) generate
    ibufdata : IBUFDS
      generic map (                     --
        DIFF_TERM    => true,           -- Differential Termination
        IBUF_LOW_PWR => true   -- Low power="TRUE", Highest performance="FALSE"
        )
      port map (
        O  => data_ibuf,
        I  => data_i_p,
        IB => data_i_n
        );
  end generate;

  single_ended_gen : if (not DIFFERENTIAL_DATA) generate
    IBUF_inst : IBUF
      generic map (
        IBUF_LOW_PWR => true,  -- Low power (TRUE) vs. performance (FALSE) setting for referenced I/O standards
        IOSTANDARD   => "DEFAULT")
      port map (
        O => data_ibuf,                 -- Buffer output
        I => data_i_p  -- Buffer input (connect directly to top-level port)
        );
  end generate;

  idelay_inst : entity work.idelay
    generic map (PATTERN => "DATA")
    port map (
      clock => clk200,
      taps  => fine_delay,
      din   => data_ibuf,
      dout  => data_idelay
      );

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
      if (posneg = '1') then
        data_r <= data_pos;
      else
        data_r <= data_neg;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- coarse delays
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then

      --------------------------------------------------------------------------------
      -- shift register
      --------------------------------------------------------------------------------

      data_srl(0) <= data_r;
      for SR in 1 to 15 loop
        data_srl(SR) <= data_srl(SR-1);
      end loop;

      --------------------------------------------------------------------------------
      -- output mux
      --------------------------------------------------------------------------------

      if (en = '1') then
        if (to_integer(unsigned(coarse_delay)) = 0) then
          data_o <= data_r;
        else
          data_o <= data_srl (to_integer(unsigned(coarse_delay)-1));
        end if;
      else
        data_o <= '0';
      end if;

    end if;
  end process;

end behavioral;
