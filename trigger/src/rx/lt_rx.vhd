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
  port(

    clk   : in std_logic;
    clk90 : in std_logic;

    coarse_delay : in coarse_delay_t;
    en           : in std_logic;

    data_i : in  std_logic;
    data_o : out std_logic

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

  signal data_oversample : std_logic := '0';

  signal data_srl : std_logic_vector (15 downto 0);

begin


  oversample_inst : entity work.oversample
    port map (
      clk    => clk,
      clk90  => clk90,
      data_i => data_i,
      data_o => data_oversample
      );

  --------------------------------------------------------------------------------
  -- coarse delays
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then

      --------------------------------------------------------------------------------
      -- shift register
      --------------------------------------------------------------------------------

      data_srl(0) <= data_oversample;
      for SR in 1 to 15 loop
        data_srl(SR) <= data_srl(SR-1);
      end loop;

      --------------------------------------------------------------------------------
      -- output mux
      --------------------------------------------------------------------------------

      if (en = '1') then
        if (to_integer(unsigned(coarse_delay)) = 0) then
          data_o <= data_oversample;
        else
          data_o <= data_srl (to_integer(unsigned(coarse_delay)-1));
        end if;
      else
        data_o <= '0';
      end if;

    end if;
  end process;

end behavioral;
