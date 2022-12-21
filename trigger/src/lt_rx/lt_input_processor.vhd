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

use work.constants.all;
use work.mt_types.all;

entity lt_input_processor is
  generic(
    STRETCH : positive := 16
    );
  port(

    reset : in std_logic;

    clk   : in std_logic;
    clk90 : in std_logic;

    coarse_delay : in coarse_delay_t;
    en           : in std_logic;

    data_i  : in  std_logic;
    data_o  : out std_logic_vector (7 downto 0) := (others => '0');
    valid_o : out std_logic;


    sel_o : out std_logic_vector(1 downto 0)

    );
end lt_input_processor;

architecture behavioral of lt_input_processor is

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

  signal data_dly : std_logic;

  signal rdy, err : std_logic := '0';

  constant zero_cnt_max : integer                         := 2047;
  signal zero_count     : integer range 0 to zero_cnt_max := 0;

  signal valid    : std_logic                             := '0';
  signal valid_sr : std_logic_vector (STRETCH-1 downto 0) := (others => '0');

begin

  --------------------------------------------------------------------------------
  -- Oversampler
  --
  -- Samples the data on the correct clock phase
  -- 1 bit in, 1 bit out
  --
  --------------------------------------------------------------------------------

  oversample_inst : entity work.oversample
    port map (
      clk    => clk,
      clk90  => clk90,
      data_i => data_i,
      data_o => data_oversample,
      sel_o  => sel_o
      );

  --------------------------------------------------------------------------------
  -- Coarse delays
  --
  -- Delay the input data in 5 ns increments to account for cable delays
  --
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then

      data_srl(0) <= data_oversample;
      for SR in 1 to 15 loop
        data_srl(SR) <= data_srl(SR-1);
      end loop;

      if (en = '1') then
        if (to_integer(unsigned(coarse_delay)) = 0) then
          data_dly <= data_oversample;
        else
          data_dly <= data_srl (to_integer(unsigned(coarse_delay)-1));
        end if;
      else
        data_dly <= '0';
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Deserializer
  --
  -- Take in the LT serial data, output bytes after finding a start bit
  --
  -- 1 bit in, 8 bits + valid out
  --
  --------------------------------------------------------------------------------

  -- deserializes the 200 MHz single bit serial data and puts out a parallel
  -- data output 8 bits wide

  lt_deserializer_inst : entity work.lt_deserializer
    generic map (
      WORD_SIZE => NUM_LT_BITS
      )
    port map (
      clock   => clk,
      reset   => reset or not rdy,
      data_i  => data_dly,
      valid_o => valid,
      data_o  => data_o,
      err_o   => err
      );

  --------------------------------------------------------------------------------
  -- Valid Extension
  --
  -- Signals from the 2 LT links may arrive out of time, so extend them a few
  -- clocks to allow them to overlap
  --
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (valid = '1') then
        valid_sr <= (others => '1');
      else
        valid_sr <= '0' & valid_sr(valid_sr'length-1 downto 1);
      end if;
    end if;
  end process;

  valid_o <= valid_sr(0);

  --------------------------------------------------------------------------------
  -- Error Monitoring
  --------------------------------------------------------------------------------

  -- use some primitive logic to find links that don't appear to be noise or
  -- super hot or accidentally inverted etc by looking for a long series of 0 bits
  process (clk) is
  begin
    if (rising_edge(clk)) then
      if (zero_count = zero_cnt_max) then
        zero_count <= zero_count;
        rdy        <= '1';
      elsif (data_dly = '0') then
        zero_count <= zero_count + 1;
        rdy        <= '0';
      else
        zero_count <= 0;
        rdy        <= '0';
      end if;

      if (err = '1' or reset = '1') then
        zero_count <= 0;
      end if;
    end if;
  end process;

end behavioral;
