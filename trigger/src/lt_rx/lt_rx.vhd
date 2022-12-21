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
-- Applies coarse delays to the inputs to align hits as best as we can:
--
-- Outputs a collection of low threshold, medium threshold, and high threshold hits
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
use work.components.all;

library xpm;
use xpm.vcomponents.all;

entity lt_rx is
  generic(
    NUM_INPUTS : positive := NUM_LT_MT_PRI
    );
  port(

    reset_i : in std_logic;

    clk   : in std_logic;
    clk90 : in std_logic;

    link_en : in std_logic_vector (NUM_INPUTS-1 downto 0);

    data_i : in std_logic_vector (NUM_INPUTS-1 downto 0);

    coarse_delays_i : in lt_coarse_delays_array_t;

    hits_o : out threshold_array_t
    );
end lt_rx;

architecture rtl of lt_rx is

  signal reset : std_logic := '0';

  signal data_bytes       : t_std8_array (NUM_INPUTS-1 downto 0);
  signal data_bytes_valid : std_logic_vector (NUM_INPUTS-1 downto 0) := (others => '0');
  signal data_rx          : std_logic_vector (NUM_INPUTS-1 downto 0);
  signal data_valid       : std_logic_vector (NUM_INPUTS-1 downto 0);
  signal coarse_delays    : lt_coarse_delays_array_t;

begin

  --------------------------------------------------------------------------------
  -- Reset
  --------------------------------------------------------------------------------

  xpm_cdc_sync_rst_inst : xpm_cdc_sync_rst
    generic map (
      DEST_SYNC_FF   => 4,              -- DECIMAL; range: 2-10
      INIT           => 1,  -- DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization registers to 1
      INIT_SYNC_FF   => 0,  -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 0  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      )
    port map (
      dest_rst => reset,  -- 1-bit output: src_rst synchronized to the destination clock domain. This output is registered.
      dest_clk => clk,                  -- 1-bit input: Destination clock.
      src_rst  => reset_i               -- 1-bit input: Source reset signal.
      );

  --------------------------------------------------------------------------------
  -- Input registers
  --------------------------------------------------------------------------------

  process (clk) is
  begin
    if (rising_edge(clk)) then
      coarse_delays <= coarse_delays_i;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Input Deserializer
  --------------------------------------------------------------------------------

  assert data_bytes(0)'length = NUM_LT_BITS
    report "input rx data width does not match constant" severity error;

  genloop : for I in 0 to NUM_INPUTS-1 generate
    signal data_serial : std_logic;
    signal sel         : std_logic_vector (1 downto 0) := (others => '0');
  begin

    ilagen : if (I = 2) generate
      ila_200_inst : ila_200
        port map (
          clk                => clk,
          probe0(0)          => data_rx(I),
          probe1(0)          => data_rx(I+1),
          probe2(0)          => data_valid(I),
          probe2(1)          => data_valid(I+1),
          probe2(2)          => link_en(I),
          probe2(3)          => link_en(I+1),
          -- probe2(2)          => data_bytes_valid(I),
          -- probe2(3)          => data_bytes_valid(I+1),
          probe2(4)          => '1',
          probe2(5)          => '1',
          probe2(7 downto 6) => sel,
          probe3             => hits_o(0),
          probe4             => hits_o(1),
          probe5             => hits_o(2),
          probe6             => hits_o(3),
          probe7             => hits_o(4),
          probe8             => hits_o(5),
          probe9             => hits_o(6),
          probe10            => hits_o(7)
          );
    end generate;

    -- input delays + ffs for single LT board
    lt_input_processor_inst : entity work.lt_input_processor
      port map (
        clk   => clk,
        clk90 => clk90,
        reset => reset,

        coarse_delay => coarse_delays(I),

        en      => link_en(I),
        data_i  => data_i(I),
        data_o  => data_bytes(I),
        valid_o => data_valid(I),
        sel_o   => sel
        );

  end generate;

  --------------------------------------------------------------------------------
  -- LT data unpacker
  --------------------------------------------------------------------------------

  genloop2 : for I in 0 to NUM_INPUTS/2 - 1 generate
    signal valid_a : std_logic := '0';
    signal valid_b : std_logic := '0';
  begin

    valid_a <= data_bytes_valid(I*2);
    valid_b <= data_bytes_valid((I+1)*2-1);

    --
    -- https://gaps1.astro.ucla.edu/wiki/gaps/index.php?title=Local_Trigger_Board_Operation
    --
    -- LT (at lest in the current scheme) is doing an AND for each paddle
    --
    --      | no hit| thr0 | thr1 | thr2
    -- -----+-------+------+------+------
    -- bit0 |    0  |  0   |  1   |  1
    -- bit1 |    0  |  1   |  0   |  1
    --
    -- LINK0 = START bit + paddles bit 0 (9 bits total)
    -- LINK1 = START bit + paddles bit 1 (9 bits total)
    --
    -- paddle 0 ~> paddle 1 ~> etc
    --
    -- ltb shifts out MSB first
    --
    -- data word = {start, A, B, C, D, E, F, G, H};
    --
    process (clk) is
    begin
      if (rising_edge(clk)) then
        for J in 0 to 7 loop
          if (valid_a = '1' and valid_b = '1') then
            hits_o(I*8+J) <= data_bytes((I+1)*2-1)(J) & data_bytes(I*2)(J);
          else
            hits_o(I*8+J) <= (others => '0');
          end if;
        end loop;
      end if;
    end process;

  end generate;

end rtl;
