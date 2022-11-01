----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- MT Trigger RX
----------------------------------------------------------------------------------
--
-- Takes in data from the LT boards and deserializes it
--
-- Applies pulse stretching to the inputs to accomodate time resolution slop
--    0-15 clock cycles long
--
-- Applies fine delays and coarse delays to the inputs to align hits as best as
-- we can:
--
--   Fine delay: delay the input signal in units of ~78 ps using the IO delays,
--                0-31 delay settings
--
--   Coarse delay:  delay the input signal in units of integer clock cycles
--                0-15 clock cycles long (1 SRL16)
--
-- Applies a posneg parameter which chooses deserialization on the positive or
-- negative edge of the clock (shouldn't matter since the inputs are async)
--
-- Outputs a collection of low threshold, medium threshold, and high threshold
-- hits
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.mt_types.all;

entity input_rx is
  generic(
    NUM_INPUTS : positive := NUM_LT_INPUTS
    );
  port(

    clk   : in std_logic;
    clk90 : in std_logic;

    link_en : in std_logic_vector (NUM_LT_INPUTS-1 downto 0);

    data_i_p : in std_logic_vector (NUM_LT_INPUTS-1 downto 0);
    data_i_n : in std_logic_vector (NUM_LT_INPUTS-1 downto 0);

    pulse_stretch_i : in std_logic_vector (3 downto 0);

    coarse_delays_i : in lt_coarse_delays_array_t;

    hits_o : out channel_array_t
    );
end input_rx;

architecture rtl of input_rx is

  signal data : lt_channel_array_t;
  signal hits : channel_array_t;

  type hit_stretch_cnt_array_t is array (integer range <>) of
    std_logic_vector(pulse_stretch_i'range);
  signal hit_stretch_cnt : hit_stretch_cnt_array_t(hits'length-1 downto 0)
    := (others => (others => '0'));

begin

  genloop : for I in 0 to NUM_LT_INPUTS-1 generate
    signal data_i : std_logic;
  begin

    -- input delays + ffs for single LT board
    lt_rx_inst : entity work.lt_rx
      generic map (
        DIFFERENTIAL_DATA => true
        )
      port map (
        clk   => clk,
        clk90 => clk90,

        coarse_delay => coarse_delays_i(I),

        en       => link_en(I),
        data_i_p => data_i_p(I),
        data_i_n => data_i_n(I),
        data_o   => data_i
        );

    -- deserializes the XX MHz single bit serial data and puts out a parallel
    -- data output 16 bits wide

    rx_deserializer_inst : entity work.rx_deserializer
      generic map (
        WORD_SIZE => NUM_LT_BITS
        )
      port map (
        clock  => clk,
        data_i => data_i,
        data_o => open                  -- data (I)
        );

    -- FIXME
    -- need to process the LT words into hits
    -- no idea how
    -- take the N words from a single LT board and process them into hits

  end generate;

  --------------------------------------------------------------------------------
  -- Output hit processing / pulse stretching
  --------------------------------------------------------------------------------

  hits <= reshape(data);

  process (clk) is
  begin
    if (rising_edge(clk)) then

      for I in 0 to hits_o'length-1 loop

        if (to_integer(unsigned(hit_stretch_cnt(I))) = 0) then
          hits_o(I) <= hits(I);
        elsif (to_integer(unsigned(hit_stretch_cnt(I))) /= 0) then
          hits_o(I) <= '1';
        else
          hits_o(I) <= '0';
        end if;


        if (hits(i) = '1') then
          hit_stretch_cnt(I) <= pulse_stretch_i;
        elsif (to_integer(unsigned(hit_stretch_cnt(I))) /= 0) then
          hit_stretch_cnt(I) <=
            std_logic_vector(unsigned(hit_stretch_cnt(I))-1);
        end if;

      end loop;
    end if;
  end process;

end rtl;
