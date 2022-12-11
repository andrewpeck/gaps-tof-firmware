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
use work.components.all;

library xpm;
use xpm.vcomponents.all;

entity input_rx is
  generic(
    NUM_INPUTS : positive := NUM_LT_MT_PRI;
    STRETCH    : positive := 16
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
end input_rx;

architecture rtl of input_rx is

  signal reset : std_logic := '0';

  signal data_bytes       : t_std8_array (NUM_INPUTS-1 downto 0);
  signal data_bytes_valid : std_logic_vector (NUM_INPUTS-1 downto 0) := (others => '0');
  signal data_rx          : std_logic_vector (NUM_INPUTS-1 downto 0);
  signal data_valid       : std_logic_vector (NUM_INPUTS-1 downto 0);

begin

  --------------------------------------------------------------------------------
  -- Reset
  --------------------------------------------------------------------------------

  xpm_cdc_sync_rst_inst : xpm_cdc_sync_rst
    generic map (
      DEST_SYNC_FF   => 4, -- DECIMAL; range: 2-10
      INIT           => 1, -- DECIMAL; 0=initialize synchronization registers to 0, 1=initialize synchronization registers to 1
      INIT_SYNC_FF   => 0, -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      SIM_ASSERT_CHK => 0  -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      )
    port map (
      dest_rst => reset,  -- 1-bit output: src_rst synchronized to the destination clock domain. This output is registered.
      dest_clk => clk,    -- 1-bit input: Destination clock.
      src_rst  => reset_i -- 1-bit input: Source reset signal.
      );

  --------------------------------------------------------------------------------
  -- Input Deserializer
  --------------------------------------------------------------------------------

  assert data_bytes(0)'length = NUM_LT_BITS
    report "input rx data width does not match constant" severity error;

  genloop : for I in 0 to NUM_INPUTS-1 generate
    signal data_serial : std_logic;

    constant zero_cnt_max : integer                         := 2047;
    signal zero_count     : integer range 0 to zero_cnt_max := 0;
    signal rdy, err       : std_logic                       := '0';

    signal sel : std_logic_vector (1 downto 0) := (others => '0');

    signal valid_sr : std_logic_vector (STRETCH-1 downto 0) := (others => '0');
  begin

    ilagen : if (I = 0) generate
      ila_200_inst : ila_200
        port map (
          clk                => clk,
          probe0(0)          => data_rx(I),
          probe1(0)          => data_rx(I+1),
          probe2(0)          => data_valid(I),
          probe2(1)          => data_valid(I+1),
          probe2(2)          => data_bytes_valid(I),
          probe2(3)          => data_bytes_valid(I+1),
          probe2(4)          => err,
          probe2(5)          => rdy,
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
    lt_rx_inst : entity work.lt_rx
      port map (
        clk   => clk,
        clk90 => clk90,

        coarse_delay => coarse_delays_i(I),

        en     => link_en(I),
        data_i => data_i(I),
        data_o => data_rx(I),
        sel_o  => sel
        );

    -- use some primitive logic to find links that don't appear to be noise or
    -- super hot or accidentally inverted etc by looking for a long series of 0 bits
    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (zero_count = zero_cnt_max) then
          zero_count <= zero_count;
          rdy        <= '1';
        elsif (data_rx(I) = '0') then
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

    -- deserializes the 200 MHz single bit serial data and puts out a parallel
    -- data output 8 bits wide

    rx_deserializer_inst : entity work.rx_deserializer
      generic map (
        WORD_SIZE => NUM_LT_BITS
        )
      port map (
        clock   => clk,
        reset   => reset or not rdy,
        data_i  => data_rx(I),
        valid_o => data_valid(I),
        data_o  => data_bytes(I),
        err_o   => err
        );

    process (clk) is
    begin
      if (rising_edge(clk)) then
        if (data_valid(I) = '1') then
          valid_sr <= (others => '1');
        else
          valid_sr <= '0' & valid_sr(valid_sr'length-1 downto 1);
        end if;
      end if;
    end process;

    data_bytes_valid(I) <= valid_sr(0);

  end generate;

  genloop2 : for I in 0 to NUM_INPUTS/2 - 1 generate

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
