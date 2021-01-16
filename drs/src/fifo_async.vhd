library xpm;
use xpm.vcomponents.all;

library ieee;
use ieee.std_logic_1164.all;

entity fifo_async is
  generic (
    DEPTH    : integer := 16;
    WR_WIDTH : integer := 16;
    RD_WIDTH : integer := 16
    );
  port (
    rst    : in  std_logic;
    wr_clk : in  std_logic;
    rd_clk : in  std_logic;
    wr_en  : in  std_logic;
    rd_en  : in  std_logic;
    din    : in  std_logic_vector(WR_WIDTH-1 downto 0);
    dout   : out std_logic_vector(RD_WIDTH-1 downto 0);
    valid  : out std_logic;
    full   : out std_logic;
    empty  : out std_logic
    );
end fifo_async;

architecture Behavioral of fifo_async is
  constant USE_ADV_FEATURES : std_logic_vector (15 downto 0) := (
    0      => '0',                      -- 1 = enable overflow
    1      => '0',                      -- 1 = enable prog_full
    2      => '0',                      -- 1 = enable wr_data_count
    3      => '0',                      -- 1 = enable almost_full
    4      => '0',                      -- 1 = enable wr_ack
    8      => '0',                      -- 1 = enable underflow
    9      => '0',                      -- 1 = enable prog_empty
    10     => '0',                      -- 1 = enable rd_data_count
    11     => '0',                      -- 1 = enable almost_empty
    12     => '1',                      -- 1 = enable data_valid
    others => '0'
    );

  constant USE_ADV_FEATURES_STR : string (1 to 4) := to_hstring (USE_ADV_FEATURES);

begin

  xpm_fifo_async_inst : xpm_fifo_async
    generic map (
      CDC_SYNC_STAGES     => 2,                    -- DECIMAL
      DOUT_RESET_VALUE    => "0",                  -- String
      ECC_MODE            => "no_ecc",             -- no_ecc, en_ecc
      FIFO_MEMORY_TYPE    => "auto",               -- auto, block, distributed, ultra
      FIFO_READ_LATENCY   => 1,                    -- DECIMAL
      FIFO_WRITE_DEPTH    => DEPTH,                -- DECIMAL
      FULL_RESET_VALUE    => 0,                    -- DECIMAL
      PROG_EMPTY_THRESH   => 5,                    -- DECIMAL
      PROG_FULL_THRESH    => 5,                    -- DECIMAL
      RD_DATA_COUNT_WIDTH => 5,                    -- DECIMAL
      READ_DATA_WIDTH     => RD_WIDTH,             -- DECIMAL
      read_mode           => "std",                -- std or fwft
      RELATED_CLOCKS      => 0,                    -- DECIMAL
      USE_ADV_FEATURES    => USE_ADV_FEATURES_STR, -- String
      WAKEUP_TIME         => 0,                    -- 0 = disable sleep, 2 = use sleep pin
      WRITE_DATA_WIDTH    => WR_WIDTH,             -- DECIMAL
      WR_DATA_COUNT_WIDTH => 5                     -- DECIMAL
      )
    port map (
      almost_empty  => open,   -- 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
      almost_full   => open,   -- 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
      data_valid    => valid,  -- 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
      dbiterr       => open,   -- 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
      dout          => dout,   -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven when reading the FIFO.
      empty         => empty,  -- 1-bit output: Empty Flag: When asserted, this signal indicates that the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
      full          => full,   -- 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
      overflow      => open,   -- 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.
      prog_empty    => open,   -- 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
      prog_full     => open,   -- 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.
      rd_data_count => open,   -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
      rd_rst_busy   => open,   -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
      sbiterr       => open,   -- 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
      underflow     => open,   -- 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
      wr_ack        => open,   -- 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
      wr_data_count => open,   -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
      wr_rst_busy   => open,   -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
      din           => din,    -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when writing the FIFO.
      injectdbiterr => '0',    -- 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
      injectsbiterr => '0',    -- 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
      rd_clk        => rd_clk, -- 1-bit input: Read clock: Used for read operation. rd_clk must be a free running clock.
      rd_en         => rd_en,  -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high. .
      rst           => rst,    -- 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
      sleep         => '0',    -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo block is in power saving mode.
      wr_clk        => wr_clk, -- 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
      wr_en         => wr_en   -- 1-bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO Must be held active-low when rst or wr_rst_busy or rd_rst_busy is active high
      );

end Behavioral;
