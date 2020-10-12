library work;
use work.ipbus_pkg.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library dma;

library UNISIM;
use UNISIM.vcomponents.all;

entity ps_interface is
  port (
    fixed_io_mio      : inout std_logic_vector (53 downto 0);
    fixed_io_ddr_vrn  : inout std_logic;
    fixed_io_ddr_vrp  : inout std_logic;
    fixed_io_ps_srstb : inout std_logic;
    fixed_io_ps_clk   : inout std_logic;
    fixed_io_ps_porb  : inout std_logic;
    ddr_cas_n         : inout std_logic;
    ddr_cke           : inout std_logic;
    ddr_ck_n          : inout std_logic;
    ddr_ck_p          : inout std_logic;
    ddr_cs_n          : inout std_logic;
    ddr_reset_n       : inout std_logic;
    ddr_odt           : inout std_logic;
    ddr_ras_n         : inout std_logic;
    ddr_we_n          : inout std_logic;
    ddr_ba            : inout std_logic_vector (2 downto 0);
    ddr_addr          : inout std_logic_vector (14 downto 0);
    ddr_dm            : inout std_logic_vector (3 downto 0);
    ddr_dq            : inout std_logic_vector (31 downto 0);
    ddr_dqs_n         : inout std_logic_vector (3 downto 0);
    ddr_dqs_p         : inout std_logic_vector (3 downto 0);

    fifo_data_in  : in std_logic_vector (15 downto 0);
    fifo_clock_in : in std_logic;
    fifo_data_wen : in std_logic;

    -- AXI CLK--
    clk33_axi : in std_logic;

    ipb_reset    : out std_logic;
    ipb_clk      : out std_logic;
    ipb_miso_arr : in  ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    ipb_mosi_arr : out ipb_wbus_array(IPB_SLAVES - 1 downto 0);

    dma_reset : in std_logic
    );

end ps_interface;

architecture Behavioral of ps_interface is

  signal s00_axi_aclk    : std_logic;
  signal s00_axi_aresetn : std_logic;
  signal s00_axi_awaddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
  signal s00_axi_awprot  : std_logic_vector(2 downto 0);
  signal s00_axi_awvalid : std_logic;
  signal s00_axi_awready : std_logic;
  signal s00_axi_wdata   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal s00_axi_wstrb   : std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
  signal s00_axi_wvalid  : std_logic;
  signal s00_axi_wready  : std_logic;
  signal s00_axi_bresp   : std_logic_vector(1 downto 0);
  signal s00_axi_bvalid  : std_logic;
  signal s00_axi_bready  : std_logic;
  signal s00_axi_araddr  : std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
  signal s00_axi_arprot  : std_logic_vector(2 downto 0);
  signal s00_axi_arvalid : std_logic;
  signal s00_axi_arready : std_logic;
  signal s00_axi_rdata   : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
  signal s00_axi_rresp   : std_logic_vector(1 downto 0);
  signal s00_axi_rvalid  : std_logic;
  signal s00_axi_rready  : std_logic;

  signal m_axi_s2mm_awid    : std_logic_vector(3 downto 0);
  signal m_axi_s2mm_awaddr  : std_logic_vector(31 downto 0);
  signal m_axi_s2mm_awlen   : std_logic_vector(7 downto 0);
  signal m_axi_s2mm_awsize  : std_logic_vector(2 downto 0);
  signal m_axi_s2mm_awburst : std_logic_vector(1 downto 0);
  signal m_axi_s2mm_awprot  : std_logic_vector(2 downto 0);
  signal m_axi_s2mm_awcache : std_logic_vector(3 downto 0);
  signal m_axi_s2mm_awuser  : std_logic_vector(3 downto 0);
  signal m_axi_s2mm_awvalid : std_logic;
  signal m_axi_s2mm_awready : std_logic;
  signal m_axi_s2mm_wdata   : std_logic_vector(31 downto 0);
  signal m_axi_s2mm_wstrb   : std_logic_vector(3 downto 0);
  signal m_axi_s2mm_wlast   : std_logic;
  signal m_axi_s2mm_wvalid  : std_logic;
  signal m_axi_s2mm_wready  : std_logic;
  signal m_axi_s2mm_bresp   : std_logic_vector(1 downto 0);
  signal m_axi_s2mm_bvalid  : std_logic;
  signal m_axi_s2mm_bready  : std_logic;
  signal m_axi_mm2s_arid    : std_logic_vector(3 downto 0);
  signal m_axi_mm2s_araddr  : std_logic_vector(31 downto 0);
  signal m_axi_mm2s_arlen   : std_logic_vector(7 downto 0);
  signal m_axi_mm2s_arsize  : std_logic_vector(2 downto 0);
  signal m_axi_mm2s_arburst : std_logic_vector(1 downto 0);
  signal m_axi_mm2s_arprot  : std_logic_vector(2 downto 0);
  signal m_axi_mm2s_arcache : std_logic_vector(3 downto 0);
  signal m_axi_mm2s_aruser  : std_logic_vector(3 downto 0);
  signal m_axi_mm2s_arvalid : std_logic;
  signal m_axi_mm2s_arready : std_logic;
  signal m_axi_mm2s_rdata   : std_logic_vector(31 downto 0);
  signal m_axi_mm2s_rresp   : std_logic_vector(1 downto 0);
  signal m_axi_mm2s_rlast   : std_logic;
  signal m_axi_mm2s_rvalid  : std_logic;
  signal m_axi_mm2s_rready  : std_logic;

  -------------------------- AXI-IPbus bridge ---------------------------------

  --AXI
  signal axi_clk      : std_logic;
  signal axi_reset    : std_logic;
  signal ipb_axi_mosi : t_axi_lite_mosi;
  signal ipb_axi_miso : t_axi_lite_miso;

begin

  gaps_dma_controller_rev1_v1_0_1 : entity dma.gaps_dma_controller_rev1_v1_0
    generic map (
      c_s00_axi_data_width => 32,
      c_s00_axi_addr_width => 32,
      c_s01_axi_data_width => 32,
      c_s01_axi_addr_width => 32,
      words_to_send        => words_to_send,
      max_address          => max_address,
      head                 => head,
      tail                 => tail
      )
    port map (

      clk_in     => fifo_clock_in,
      rst_in     => dma_reset,
      fifo_in    => fifo_data_in,
      fifo_wr_en => fifo_data_wen,
      fifo_full  => fifo_full,

      s00_axi_aclk    => s00_axi_aclk,
      s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_awaddr  => s00_axi_awaddr,
      s00_axi_awprot  => s00_axi_awprot,
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_awready => s00_axi_awready,
      s00_axi_wdata   => s00_axi_wdata,
      s00_axi_wstrb   => s00_axi_wstrb,
      s00_axi_wvalid  => s00_axi_wvalid,
      s00_axi_wready  => s00_axi_wready,
      s00_axi_bresp   => s00_axi_bresp,
      s00_axi_bvalid  => s00_axi_bvalid,
      s00_axi_bready  => s00_axi_bready,
      s00_axi_araddr  => s00_axi_araddr,
      s00_axi_arprot  => s00_axi_arprot,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_arready => s00_axi_arready,
      s00_axi_rdata   => s00_axi_rdata,
      s00_axi_rresp   => s00_axi_rresp,
      s00_axi_rvalid  => s00_axi_rvalid,
      s00_axi_rready  => s00_axi_rready,

      m_axi_s2mm_awid    => m_axi_s2mm_awid,
      m_axi_s2mm_awaddr  => m_axi_s2mm_awaddr,
      m_axi_s2mm_awlen   => m_axi_s2mm_awlen,
      m_axi_s2mm_awsize  => m_axi_s2mm_awsize,
      m_axi_s2mm_awburst => m_axi_s2mm_awburst,
      m_axi_s2mm_awprot  => m_axi_s2mm_awprot,
      m_axi_s2mm_awcache => m_axi_s2mm_awcache,
      m_axi_s2mm_awuser  => m_axi_s2mm_awuser,
      m_axi_s2mm_awvalid => m_axi_s2mm_awvalid,
      m_axi_s2mm_awready => m_axi_s2mm_awready,
      m_axi_s2mm_wdata   => m_axi_s2mm_wdata,
      m_axi_s2mm_wstrb   => m_axi_s2mm_wstrb,
      m_axi_s2mm_wlast   => m_axi_s2mm_wlast,
      m_axi_s2mm_wvalid  => m_axi_s2mm_wvalid,
      m_axi_s2mm_wready  => m_axi_s2mm_wready,
      m_axi_s2mm_bresp   => m_axi_s2mm_bresp,
      m_axi_s2mm_bvalid  => m_axi_s2mm_bvalid,
      m_axi_s2mm_bready  => m_axi_s2mm_bready,
      m_axi_mm2s_arid    => m_axi_mm2s_arid,
      m_axi_mm2s_araddr  => m_axi_mm2s_araddr,
      m_axi_mm2s_arlen   => m_axi_mm2s_arlen,
      m_axi_mm2s_arsize  => m_axi_mm2s_arsize,
      m_axi_mm2s_arburst => m_axi_mm2s_arburst,
      m_axi_mm2s_arprot  => m_axi_mm2s_arprot,
      m_axi_mm2s_arcache => m_axi_mm2s_arcache,
      m_axi_mm2s_aruser  => m_axi_mm2s_aruser,
      m_axi_mm2s_arvalid => m_axi_mm2s_arvalid,
      m_axi_mm2s_arready => m_axi_mm2s_arready,
      m_axi_mm2s_rdata   => m_axi_mm2s_rdata,
      m_axi_mm2s_rresp   => m_axi_mm2s_rresp,
      m_axi_mm2s_rlast   => m_axi_mm2s_rlast,
      m_axi_mm2s_rvalid  => m_axi_mm2s_rvalid,
      m_axi_mm2s_rready  => m_axi_mm2s_rready
      );

  ------------------------------------------------------------------------------------------------------------------------
  -- AXI IPBus (Wishbone) Bridge
  ------------------------------------------------------------------------------------------------------------------------

  i_axi_ipbus_bridge : entity work.axi_ipbus_bridge
    generic map(
      C_NUM_IPB_SLAVES   => IPB_SLAVES,
      C_S_AXI_DATA_WIDTH => C_IPB_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH => C_IPB_AXI_ADDR_WIDTH
      )
    port map(
      ipb_reset_o   => ipb_reset,
      ipb_clk_o     => ipb_clk,
      ipb_miso_i    => ipb_miso_arr,
      ipb_mosi_o    => ipb_mosi_arr,
      S_AXI_ACLK    => axi_clk,
      S_AXI_ARESETN => axi_reset,
      S_AXI_ARADDR  => ipb_axi_mosi.araddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
      S_AXI_ARPROT  => ipb_axi_mosi.arprot,
      S_AXI_ARREADY => ipb_axi_miso.arready,
      S_AXI_ARVALID => ipb_axi_mosi.arvalid,
      S_AXI_AWADDR  => ipb_axi_mosi.awaddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
      S_AXI_AWPROT  => ipb_axi_mosi.awprot,
      S_AXI_AWREADY => ipb_axi_miso.awready,
      S_AXI_AWVALID => ipb_axi_mosi.awvalid,
      S_AXI_BREADY  => ipb_axi_mosi.bready,
      S_AXI_BRESP   => ipb_axi_miso.bresp,
      S_AXI_BVALID  => ipb_axi_miso.bvalid,
      S_AXI_RDATA   => ipb_axi_miso.rdata,
      S_AXI_RRESP   => ipb_axi_miso.rresp,
      S_AXI_RVALID  => ipb_axi_miso.rvalid,
      S_AXI_WDATA   => ipb_axi_mosi.wdata,
      S_AXI_WREADY  => ipb_axi_miso.wready,
      S_AXI_WVALID  => ipb_axi_mosi.wvalid,
      S_AXI_WSTRB   => ipb_axi_mosi.wstrb,
      S_AXI_RREADY  => ipb_axi_mosi.rready
      );

end Behavioral;
