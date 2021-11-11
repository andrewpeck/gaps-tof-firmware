
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;
use work.mt_types.all;

entity input_rx is
  generic(
    NUM_INPUTS : positive := NUM_LT_INPUTS;
    NUM_CLOCKS : positive := NUM_LT_CLOCKS
    );
  port(
    clk    : in std_logic;
    clk200 : in std_logic;              -- for idelay

    clocks_i : in std_logic_vector (NUM_CLOCKS-1 downto 0);

    data_i : in std_logic_vector (NUM_LT_INPUTS-1 downto 0);

    pulse_stretch_i : in std_logic_vector (3 downto 0);

    fine_delays_i   : in lt_fine_delays_array_t;
    coarse_delays_i : in lt_coarse_delays_array_t;
    posnegs_i       : in lt_posnegs_array_t;

    hits_o : out channel_array_t
    );
end input_rx;

architecture rtl of input_rx is

  signal clocks : std_logic_vector (NUM_CLOCKS-1 downto 0) := (others => '0');

  signal data : lt_channel_array_t;
  signal hits : channel_array_t;

  type hit_stretch_cnt_array_t is array (integer range <>) of
    std_logic_vector(pulse_stretch_i'range);
  signal hit_stretch_cnt : hit_stretch_cnt_array_t(hits'length-1 downto 0)
    := (others => (others => '0'));

begin

  genloop : for I in 0 to NUM_LTS-1 generate
    signal data_rx : std_logic_vector(NUM_LT_MT_LINKS-1 downto 0);
  begin

    -- input delays + ffs for single LT board
    lt_rx_1 : entity work.lt_rx
      generic map (
        DIFFERENTIAL_DATA  => false,
        DIFFERENTIAL_CLOCK => false,
        NUM_LT_CHANNELS    => NUM_LT_MT_LINKS
        )
      port map (
        clk    => clk,
        clk200 => clk200,               -- for idelay

        fine_delays   => fine_delays_i(I),
        coarse_delays => coarse_delays_i(I),
        posnegs       => posnegs_i(I),

        data_i_p => data_i((I+1)*NUM_LT_MT_LINKS-1 downto I*NUM_LT_MT_LINKS),
        data_i_n => (others => '0'),
        data_o   => data_rx
        );

    -- deserializes the XX MHz single bit serial data and puts out a parallel
    -- data output 16 bits wide
    rx_deserializer_inst : entity work.rx_deserializer
      generic map (
        NCH       => NUM_LT_MT_LINKS,
        WORD_SIZE => NUM_LT_BITS
        )
      port map (
        clock  => clk,
        data_i => data_rx,
        data_o => data (I)
        );

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

-- prbs_any_gen : entity work.prbs_any
--   generic map (
--     chk_mode    => false,
--     inv_pattern => false,
--     poly_lenght => 7,
--     poly_tap    => 6,
--     nbits       => 2
--     )
--   port map (
--     rst      => reset,
--     clk      => clock_o,
--     data_in  => (others => '0'),
--     en       => '1',
--     data_out => data_gen
--     );
-- oversamplegen : if (MODE = "OVERSAMPLE") generate

--   delayctrl_inst : IDELAYCTRL
--     port map (
--       RDY    => open,
--       REFCLK => clk100,
--       RST    => not locked
--       );

--   loopgen : for I in 0 to NUM_INPUTS-1 generate
--   begin
--     oversample_1 : entity work.oversample
--       port map (
--         clk1x_logic       => clk25,
--         clk1x             => clk25,
--         clk4x_0           => clk100,
--         clk4x_90          => clk100_90,
--         reset_i           => '0',
--         data_p            => data_i(I),
--         rxdata_o          => data(8*(I+1)-1 downto 8*I),
--         invert            => '0',
--         tap_delay_i       => (others => '0'),
--         e4_in             => (others => '0'),
--         e4_out            => open,
--         phase_sel_in      => (others => '0'),
--         phase_sel_out     => open,
--         invalid_bitskip_o => open
--         );
--   end generate;
-- end generate;

-- ssgen : if (MODE = "FF") generate

--   clkgen : for I in 0 to NUM_CLOCKS-1 generate
--   begin

--     bufr_inst : BUFR
--       generic map (
--         SIM_DEVICE  => "7SERIES",
--         BUFR_DIVIDE => "BYPASS")
--       port map (
--         O   => clocks(I),
--         CE  => '1',
--         CLR => '0',
--         I   => clocks_i(I)
--         );
--   end generate;

--   loopgen : for I in 0 to NUM_INPUTS-1 generate
--     signal thisclock : std_logic := '0';
--   begin

--     thisclock <= clocks(I/4);

--     process (thisclock) is
--     begin
--       if (rising_edge(thisclock)) then
--         data(I) <= data_i(I);
--       end if;
--     end process;
--   end generate;
-- end generate;


-- outgen : for I in 0 to NUM_OUTPUTS-1 generate
-- begin

--   process (clk25) is
--   begin
--     if (rising_edge(clk25)) then
--       sump    <= xor_reduce(data);
--       sump_r  <= sump;
--       sump_rr <= sump_r;
--       data_o  <= (others => sump_rr);
--     end if;
--   end process;

-- end generate;
