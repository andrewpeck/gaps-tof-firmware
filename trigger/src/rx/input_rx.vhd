----------------------------------------------------------------------------------
-- GAPS Time of Flight
-- A. Peck
-- MT Trigger RX
----------------------------------------------------------------------------------
--
-- Takes in data from the LT boards and deserializes it
--
-- Applies pulse stretching to the inputs to accomodate time resolution slop
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
use work.types_pkg.all;

entity input_rx is
  generic(
    NUM_INPUTS : positive := NUM_LT_MT_PRI;
    STRETCH    : positive := 16
    );
  port(

    clk   : in std_logic;
    clk90 : in std_logic;

    link_en : in std_logic_vector (NUM_INPUTS-1 downto 0);

    data_i : in std_logic_vector (NUM_INPUTS-1 downto 0);

    coarse_delays_i : in lt_coarse_delays_array_t;

    hits_o : out threshold_array_t
    );
end input_rx;

architecture rtl of input_rx is

  signal data_bytes       : t_std8_array (NUM_INPUTS-1 downto 0);
  signal data_bytes_valid : std_logic_vector (NUM_INPUTS-1 downto 0) := (others => '0');

begin

  assert data_bytes(0)'length = NUM_LT_BITS
    report "input rx data width does not match constant" severity error;

  genloop : for I in 0 to NUM_INPUTS-1 generate
    signal data_serial : std_logic;
    signal valid       : std_logic                             := '0';
    signal valid_sr    : std_logic_vector (STRETCH-1 downto 0) := (others => '0');
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
        data_i   => data_i(I),
        data_o   => data_serial
        );

    -- deserializes the 200 MHz single bit serial data and puts out a parallel
    -- data output 8 bits wide

    rx_deserializer_inst : entity work.rx_deserializer
      generic map (
        WORD_SIZE => NUM_LT_BITS
        )
      port map (
        clock   => clk,
        data_i  => data_serial,
        valid_o => valid,
        data_o  => data_bytes(I)
        );

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

    data_bytes_valid(I) <= valid_sr(0);

  end generate;

  genloop2 : for I in 0 to NUM_INPUTS/2 - 1 generate

    -- //      | no hit| thr0 | thr1 | thr2
    -- //----------------------------------
    -- // bit0 |    0  |  0   |  1   |  1
    -- // bit1 |    0  |  1   |  0   |  1

    -- //LINK0  = START bit +paddles bit 0 (9 bits total)
    -- //LINK1 = START bit +paddles bit 1 (9 bits total)

    process (clk) is
    begin
      if (rising_edge(clk)) then
        for J in 0 to 7 loop
          if (data_bytes_valid(I*2) = '1' and data_bytes_valid((I+1)*2-1) = '1') then
            hits_o(I*8+J) <= data_bytes((I+1)*2-1)(J) & data_bytes(I*2)(J);
          else
            hits_o(I*8+J) <= (others => '0');
          end if;
        end loop;
      end if;
    end process;

  end generate;

end rtl;
