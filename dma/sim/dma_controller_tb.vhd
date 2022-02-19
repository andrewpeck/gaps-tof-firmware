----------------------------------------------------------------------------------
-- DMA Controller Test Bench
-- GAPS DRS4 Readout Firmware
-- I. Garcia, A. Peck
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

library xpm;
use xpm.vcomponents.all;

entity dma_controller_tb is
end dma_controller_tb;

architecture Behavioral of dma_controller_tb is

  type HALFWORD is array (17 downto 0) of std_logic_vector(15 downto 0);
  type HALFWORD_TRAIl is array (10 downto 0) of std_logic_vector(15 downto 0);

  signal index : integer := 0;

  signal channel_mask : std_logic_vector(15 downto 0) := x"0001";
  signal fifo_in      : std_logic_vector(15 downto 0) := x"0000";
  signal fifo_wr_en   : std_logic                     := '0';
  signal daq_busy_in  : std_logic                     := '0';

  signal ram_toggle_request : std_logic := '0';

  signal clk_logic   : std_logic := '0';
  signal clk_axi     : std_logic := '0';
  signal rst_in      : std_logic := '1';
  constant logic_per : time      := 24 ns;
  constant axi_per   : time      := 4 ns;

  signal start : std_logic := '0';

  signal wlast  : std_logic := '0';
  signal bvalid : std_logic := '0';

  signal packet_data : HALFWORD := (x"0000", x"0000", x"0000", x"0001", x"0000", x"0000",
                                    x"0000", x"0001", x"0001", x"1234", x"BAAD", x"BEEF",
                                    x"BEEF", x"BAAD", x"0000", x"0010", x"0000", x"AAAA");


  signal packet_data_trail : HALFWORD_TRAIl := (x"0000", x"0000", x"0000", x"0000", x"0000",
                                                x"0000", x"0000", x"0000", x"0000", x"0000", x"5555");

  type states is (IDLE, HEADER, PAYLOAD, TAIL, DONE);
  signal dma_state : states;

begin

  --generate clocks
  process
  begin
    wait for logic_per/2;
    clk_logic <= not clk_logic;
  end process;

  process
  begin
    wait for axi_per/2;
    clk_axi <= not clk_axi;
  end process;

  --generate start pulses every ~2us
  process
  begin
    wait for logic_per*120;

    rst_in <= '0';

    wait for logic_per*200;
    start <= '1';
    wait for logic_per*100;
    start <= '0';
    wait for logic_per*1600;
  end process;

  process
  begin
    wait for 50 us;

    wait until rising_edge(clk_axi);
    ram_toggle_request <= '1';
    wait until rising_edge(clk_axi);
    ram_toggle_request <= '0';

  end process;

  --reduced ram_buff_size to demonstrate address functionality of address split feature.

  inst_dma : entity work.dma_controller
    generic map(
      RAM_BUFF_SIZE        => 8192,
      WORDS_TO_SEND        => 16,
      MAX_PACKET_SIZE      => 2048
      )
    port map(

      clk_in  => clk_logic,
      clk_axi => clk_axi,
      reset   => rst_in,

      --------------------------------------------------------------
      -- RAM Occupancy signals
      --------------------------------------------------------------

      ram_toggle_request_i => ram_toggle_request,

      ram_a_occ_rst => '0',
      ram_b_occ_rst => '0',

      ram_buff_a_occupancy_o => open,
      ram_buff_b_occupancy_o => open,
      dma_pointer_o          => open,

      --------------------------------------------------------------
      -- DAQ Signal(s)
      --------------------------------------------------------------
      fifo_in     => fifo_in,
      fifo_wr_en  => fifo_wr_en,
      fifo_full   => open,
      daq_busy_in => daq_busy_in,

      --------------------------------------------------------------
      -- Datamover AXI4MM Signals
      --------------------------------------------------------------

      m_axi_s2mm_awid    => open,
      m_axi_s2mm_awaddr  => open,
      m_axi_s2mm_awlen   => open,
      m_axi_s2mm_awsize  => open,
      m_axi_s2mm_awburst => open,
      m_axi_s2mm_awprot  => open,
      m_axi_s2mm_awcache => open,
      m_axi_s2mm_awuser  => open,
      m_axi_s2mm_awvalid => open,
      m_axi_s2mm_awready => '1',
      m_axi_s2mm_wdata   => open,
      m_axi_s2mm_wstrb   => open,
      m_axi_s2mm_wlast   => wlast,
      m_axi_s2mm_wvalid  => open,
      m_axi_s2mm_wready  => '1',
      m_axi_s2mm_bresp   => "11",
      m_axi_s2mm_bvalid  => bvalid,
      m_axi_s2mm_bready  => open,

      m_axi_mm2s_arid    => open,
      m_axi_mm2s_araddr  => open,
      m_axi_mm2s_arlen   => open,
      m_axi_mm2s_arsize  => open,
      m_axi_mm2s_arburst => open,
      m_axi_mm2s_arprot  => open,
      m_axi_mm2s_arcache => open,
      m_axi_mm2s_aruser  => open,
      m_axi_mm2s_arvalid => open,
      m_axi_mm2s_arready => '1',
      m_axi_mm2s_rdata   => (others => '0'),
      m_axi_mm2s_rresp   => (others => '0'),
      m_axi_mm2s_rlast   => '0',
      m_axi_mm2s_rvalid  => '0',
      m_axi_mm2s_rready  => open,

      -----------------------------------------------------------------------------
      -- DMA AXI4 Lite Registers
      -----------------------------------------------------------------------------

      packet_sent_o => open,
      clear_ps_mem  => rst_in
      );

  process(clk_logic)
  begin
    if(rising_edge(clk_logic)) then
      case(dma_state) is

        when IDLE =>
          if(start = '1')then
            dma_state <= HEADER;
          else
            dma_state <= IDLE;
          end if;

          -----------------------------------------
          -- Header, DNA,etc
          -----------------------------------------

        when HEADER =>
          if(index < 18)then
            fifo_in     <= packet_data(index);
            index       <= index + 1;
            fifo_wr_en  <= '1';
            daq_busy_in <= '1';
          else
            dma_state <= PAYLOAD;
            index     <= 0;
          end if;

          ---------------------------------------------------
          -- Payload
          ---------------------------------------------------

        when PAYLOAD =>
          if(index < (unsigned(channel_mask) * 1024))then
            index   <= index + 1;
            fifo_in <= std_logic_vector(to_unsigned(index, 16));
          else
            dma_state   <= TAIL;
            daq_busy_in <= '0';
            index       <= 0;
          end if;

        ---------------------------------------------------
        -- Tail, CRC, Padded data
        ---------------------------------------------------
        when TAIL =>
          if(index < 11)then
            fifo_in <= packet_data_trail(index);
            index   <= index + 1;
          else
            dma_state <= DONE;
          end if;

        when DONE =>
          fifo_in    <= x"0000";
          index      <= 0;
          fifo_wr_en <= '0';
          dma_state  <= IDLE;

        when others => dma_state <= IDLE;

      end case;
    end if;
  end process;

  --needed for datamover core, else the IP locks up.
  process(clk_logic)
  begin
    if(rising_edge(clk_logic)) then
      bvalid <= wlast;
    end if;
  end process;

end Behavioral;
