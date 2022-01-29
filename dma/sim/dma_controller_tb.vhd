----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/01/2021 11:07:03 PM
-- Design Name: 
-- Module Name: dma_controller_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

library xpm;
use xpm.vcomponents.all;

entity dma_controller_tb is
  generic (
    constant IPB_MASTERS : integer := 1;
    constant IPB_SLAVES  : integer := 1
    );
--  Port ( );
end dma_controller_tb;

architecture Behavioral of dma_controller_tb is


  component dma_controller is
    generic (
      C_DEBUG : boolean := true;

      FIFO_LATENCY : natural := 1;

      RESET_ACTIVE : std_logic := '0';  -- set to 1 for active high, 0 for active low

      WORDS_TO_SEND : integer := 16;

      BUFF_FRAC_DIVISOR : integer := 1040384;  --Corresponds to 1/64 of RAM_BUFF_SIZE

      -- NOTE: WORDS_TO_SEND MUST NOT EXCEED MaxBurst in DataMover core (u1: axis2aximm)!

      -- TODO: make START_ADDRESS, TOP_HALF_ADDRESS programmable from userspace
      RAM_BUFF_SIZE    : integer                       := 66584576;
      START_ADDRESS    : std_logic_vector(31 downto 0) := x"04100000";
      TOP_HALF_ADDRESS : std_logic_vector(31 downto 0) := x"08100000";

      HEAD : std_logic_vector(15 downto 0) := x"AAAA";
      TAIL : std_logic_vector(15 downto 0) := x"5555"
      );
    port (

      clk_in  : in std_logic;           -- daq clock
      clk_axi : in std_logic;           -- axi clock
      rst_in  : in std_logic;           -- active high reset, synchronous to the axi clock

      --------------------------------------------------------------
      -- RAM Occupancy signals
      --------------------------------------------------------------
      ram_a_occ_rst : in std_logic;
      ram_b_occ_rst : in std_logic;


      ram_buff_a_occupancy_o : out std_logic_vector(31 downto 0) := (others => '0');
      ram_buff_b_occupancy_o : out std_logic_vector(31 downto 0) := (others => '0');
      dma_pointer_o          : out std_logic_vector(31 downto 0);


      --------------------------------------------------------------
      -- DAQ Signal(s)
      --------------------------------------------------------------
      fifo_in     : in  std_logic_vector(15 downto 0);
      fifo_wr_en  : in  std_logic;
      fifo_full   : out std_logic;
      daq_busy_in : in  std_logic;

      --------------------------------------------------------------
      -- Datamover AXI4MM Signals
      --------------------------------------------------------------

      m_axi_s2mm_awid    : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awaddr  : out std_logic_vector(31 downto 0);
      m_axi_s2mm_awlen   : out std_logic_vector(7 downto 0);
      m_axi_s2mm_awsize  : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awburst : out std_logic_vector(1 downto 0);
      m_axi_s2mm_awprot  : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awcache : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awuser  : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awvalid : out std_logic;
      m_axi_s2mm_awready : in  std_logic;
      m_axi_s2mm_wdata   : out std_logic_vector(31 downto 0);
      m_axi_s2mm_wstrb   : out std_logic_vector(3 downto 0);
      m_axi_s2mm_wlast   : out std_logic;
      m_axi_s2mm_wvalid  : out std_logic;
      m_axi_s2mm_wready  : in  std_logic;
      m_axi_s2mm_bresp   : in  std_logic_vector(1 downto 0);
      m_axi_s2mm_bvalid  : in  std_logic;
      m_axi_s2mm_bready  : out std_logic;

      m_axi_mm2s_arid    : out std_logic_vector(3 downto 0);
      m_axi_mm2s_araddr  : out std_logic_vector(31 downto 0);
      m_axi_mm2s_arlen   : out std_logic_vector(7 downto 0);
      m_axi_mm2s_arsize  : out std_logic_vector(2 downto 0);
      m_axi_mm2s_arburst : out std_logic_vector(1 downto 0);
      m_axi_mm2s_arprot  : out std_logic_vector(2 downto 0);
      m_axi_mm2s_arcache : out std_logic_vector(3 downto 0);
      m_axi_mm2s_aruser  : out std_logic_vector(3 downto 0);
      m_axi_mm2s_arvalid : out std_logic;
      m_axi_mm2s_arready : in  std_logic;
      m_axi_mm2s_rdata   : in  std_logic_vector(31 downto 0);
      m_axi_mm2s_rresp   : in  std_logic_vector(1 downto 0);
      m_axi_mm2s_rlast   : in  std_logic;
      m_axi_mm2s_rvalid  : in  std_logic;
      m_axi_mm2s_rready  : out std_logic;

      -----------------------------------------------------------------------------
      -- DMA AXI4 Lite Registers
      -----------------------------------------------------------------------------

      packet_sent_o : out std_logic_vector(31 downto 0) := (others => '0');
      reset_sys     : in  std_logic                     := '0';
      clear_ps_mem  : in  std_logic                     := '0'

      );
  end component;

  type HALFWORD is array (17 downto 0) of std_logic_vector(15 downto 0);
  type HALFWORD_TRAIl is array (10 downto 0) of std_logic_vector(15 downto 0);


  signal index    : integer := 0;
  signal index_r1 : integer := 0;

  signal channel_mask : std_logic_vector(15 downto 0) := x"0001";
  signal fifo_in      : std_logic_vector(15 downto 0) := x"0000";
  signal fifo_wr_en   : std_logic                     := '0';
  signal daq_busy_in  : std_logic                     := '0';

  signal clk_logic   : std_logic := '0';
  signal clk_axi     : std_logic := '0';
  signal rst_in      : std_logic := '1';
--constant logic_per  : time := 33.33ns;
  constant logic_per : time      := 24ns;
  constant axi_per   : time      := 4ns;

  signal counter : std_logic_vector(15 downto 0) := x"0000";
  signal start   : std_logic                     := '0';

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



--reduced ram_buff_size to demonstrate address functionality of address split feature. 

  inst_dma : dma_controller
    generic map(


      BUFF_FRAC_DIVISOR => 64,          --: integer := 1040384;  --Corresponds to 1/64 of RAM_BUFF_SIZE

      -- NOTE: WORDS_TO_SEND MUST NOT EXCEED MaxBurst in DataMover core (u1: axis2aximm)!

      -- TODO: make START_ADDRESS, TOP_HALF_ADDRESS programmable from userspace
      RAM_BUFF_SIZE => 2048,             --: integer                       := 66584576;
      WORDS_TO_SEND => 16
      --START_ADDRESS    : std_logic_vector(31 downto 0) := x"04100000";
      --TOP_HALF_ADDRESS : std_logic_vector(31 downto 0) := x"08100000";

      )
    port map(

      clk_in  => clk_logic,
      clk_axi => clk_axi,
      rst_in  => rst_in,

      --------------------------------------------------------------
      -- RAM Occupancy signals
      --------------------------------------------------------------
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
      reset_sys     => rst_in,
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
          fifo_in <= x"0000";
          index   <= 0;

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
