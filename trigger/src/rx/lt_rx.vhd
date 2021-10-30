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

  signal data_i, data_idelay, data_r :
    std_logic_vector (NUM_LT_CHANNELS-1 downto 0)
    := (others => '0');

begin

  --------------------------------------------------------------------------------
  -- RX Data
  --
  -- IBUFDS → IDELAY → IDDR
  --------------------------------------------------------------------------------

  rx_gen : for I in 0 to NUM_LT_CHANNELS-1 generate
    signal data_idelay, data_ibuf : std_logic := '0';
  begin

    diff_gen : if (DIFFERENTIAL_DATA) generate
      ibufdata : IBUFDS
        generic map (                   --
          DIFF_TERM    => true,         -- Differential Termination
          IBUF_LOW_PWR => true          -- Low power="TRUE", Highest performance="FALSE"
          )
        port map (
          O  => data_ibuf,
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
          O => data_ibuf,               -- Buffer output
          I => data_i_p(I)              -- Buffer input (connect directly to top-level port)
          );
    end generate;

    -- IDDR_data : IDDR
    --   generic map (
    --     DDR_CLK_EDGE => "SAME_EDGE_PIPELINED",  -- IDDRE1 mode (OPPOSITE_EDGE, SAME_EDGE, SAME_EDGE_PIPELINED)
    --     INIT_Q1      => '0',                    -- Initial value of Q1: '0' or '1'
    --     INIT_Q2      => '0',                    -- Initial value of Q2: '0' or '1'
    --     SRTYPE       => "SYNC"                  -- Set/Reset type: "SYNC" or "ASYNC"
    --     )
    --   port map (
    --     Q1 => data_i(2*I + 0),                  -- 1-bit output: Registered parallel output 1
    --     Q2 => data_i(2*I + 1),                  -- 1-bit output: Registered parallel output 2
    --     C  => clock_i_io,                       -- 1-bit input: High-speed clock
    --     CE => '1',                              -- 1-bit input: Inversion of High-speed clock C
    --     D  => data_idelay,                      -- 1-bit input: Serial Data Input
    --     R  => '0',                              -- 1-bit input: Active-High Async Reset
    --     S  => '0'
    --     );

    idelay_inst : entity work.idelay
      generic map (PATTERN => "DATA")
      port map (
        clock => clk200,
        taps  => fine_delays(I),
        din   => data_ibuf,
        dout  => data_idelay);

  end generate;

  process (clk) is
  begin
    if (rising_edge(clk)) then
      data_r <= data_idelay;
      data_o <= data_r;
    end if;
  end process;


end behavioral;
