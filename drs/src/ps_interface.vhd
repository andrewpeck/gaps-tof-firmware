library work;
use work.ipbus_pkg.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.vcomponents.all;

entity ps_interface is
  port (

    -- AXI For Slow Control
    DRS_S_AXI_LITE_ACLK    : out std_logic;
    DRS_S_AXI_LITE_ARESETN : out std_logic;
    DRS_S_AXI_LITE_AWADDR  : out std_logic_vector (C_IPB_AXI_ADDR_WIDTH-1 downto 0);
    DRS_S_AXI_LITE_AWPROT  : out std_logic_vector (2 downto 0);
    DRS_S_AXI_LITE_AWVALID : out std_logic;
    DRS_S_AXI_LITE_AWREADY : in  std_logic;
    DRS_S_AXI_LITE_WDATA   : out std_logic_vector (C_IPB_AXI_DATA_WIDTH-1 downto 0);
    DRS_S_AXI_LITE_WSTRB   : out std_logic_vector((32/8)-1 downto 0);  -- 32 = C_S_AXI_DATA_WIDTH
    DRS_S_AXI_LITE_WVALID  : out std_logic;
    DRS_S_AXI_LITE_WREADY  : in  std_logic;
    DRS_S_AXI_LITE_BRESP   : in  std_logic_vector (1 downto 0);
    DRS_S_AXI_LITE_BVALID  : in  std_logic;
    DRS_S_AXI_LITE_BREADY  : out std_logic;
    DRS_S_AXI_LITE_ARADDR  : out std_logic_vector (C_IPB_AXI_ADDR_WIDTH-1 downto 0);
    DRS_S_AXI_LITE_ARPROT  : out std_logic_vector (2 downto 0);
    DRS_S_AXI_LITE_ARVALID : out std_logic;
    DRS_S_AXI_LITE_ARREADY : in  std_logic;
    DRS_S_AXI_LITE_RDATA   : in  std_logic_vector (C_IPB_AXI_DATA_WIDTH-1 downto 0);
    DRS_S_AXI_LITE_RRESP   : in  std_logic_vector(1 downto 0);
    DRS_S_AXI_LITE_RVALID  : in  std_logic;
    DRS_S_AXI_LITE_RREADY  : out std_logic;

    fifo_data_in  : in std_logic_vector (15 downto 0);
    fifo_clock_in : in std_logic;
    fifo_data_wen : in std_logic
    );

end ps_interface;

architecture Behavioral of ps_interface is

  component DMA_Write_v1_0
    port(
      m00_axi_aclk       : in  std_logic;
      m00_axi_aresetn    : in  std_logic;
      m00_axi_awready    : in  std_logic;
      m00_axi_wready     : in  std_logic;
      m00_axi_bid        : in  std_logic_vector(0 to 0);
      m00_axi_bresp      : in  std_logic_vector(1 downto 0);
      m00_axi_buser      : in  std_logic;
      m00_axi_bvalid     : in  std_logic;
      wr_aclk            : in  std_logic;
      din_dma            : in  std_logic_vector(31 downto 0);
      wr_en              : in  std_logic;
      s_axi_lite_araddr  : in  std_logic_vector(31 downto 0);
      s_axi_lite_arvalid : in  std_logic;
      s_axi_lite_rready  : in  std_logic;
      s_axi_lite_awaddr  : in  std_logic_vector(31 downto 0);
      s_axi_lite_awvalid : in  std_logic;
      s_axi_lite_wvalid  : in  std_logic;
      s_axi_lite_wdata   : in  std_logic_vector(31 downto 0);
      s_axi_lite_bready  : in  std_logic;
      m00_axi_awid       : out std_logic_vector(0 to 0);
      m00_axi_awaddr     : out std_logic_vector(31 downto 0);
      m00_axi_awlen      : out std_logic_vector(7 downto 0);
      m00_axi_awsize     : out std_logic_vector(2 downto 0);
      m00_axi_awburst    : out std_logic_vector(1 downto 0);
      m00_axi_awlock     : out std_logic;
      m00_axi_awcache    : out std_logic_vector(3 downto 0);
      m00_axi_awprot     : out std_logic_vector(2 downto 0);
      m00_axi_awqos      : out std_logic_vector(3 downto 0);
      m00_axi_awuser     : out std_logic;
      m00_axi_awvalid    : out std_logic;
      m00_axi_wdata      : out std_logic_vector(31 downto 0);
      m00_axi_wstrb      : out std_logic_vector(3 downto 0);
      m00_axi_wlast      : out std_logic;
      m00_axi_wuser      : out std_logic;
      m00_axi_wvalid     : out std_logic;
      m00_axi_bready     : out std_logic;
      fifo_full          : out std_logic;
      s_axi_lite_arready : out std_logic;
      s_axi_lite_rvalid  : out std_logic;
      s_axi_lite_rdata   : out std_logic_vector(31 downto 0);
      s_axi_lite_awready : out std_logic;
      s_axi_lite_wready  : out std_logic;
      s_axi_lite_bvalid  : out std_logic;
      dma_irq            : out std_logic
      );
  end component;

begin

--  DMA_Write_v1_0_1 : DMA_Write_v1_0
--    port map (
--      m00_axi_aclk       => m00_axi_aclk,
--      m00_axi_aresetn    => m00_axi_aresetn,
--      m00_axi_awready    => m00_axi_awready,
--      m00_axi_wready     => m00_axi_wready,
--      m00_axi_bid        => m00_axi_bid,
--      m00_axi_bresp      => m00_axi_bresp,
--      m00_axi_buser      => m00_axi_buser,
--      m00_axi_bvalid     => m00_axi_bvalid,
--      wr_aclk            => wr_aclk,
--      din_dma            => din_dma,
--      wr_en              => wr_en,
--      s_axi_lite_araddr  => s_axi_lite_araddr,
--      s_axi_lite_arvalid => s_axi_lite_arvalid,
--      s_axi_lite_rready  => s_axi_lite_rready,
--      s_axi_lite_awaddr  => s_axi_lite_awaddr,
--      s_axi_lite_awvalid => s_axi_lite_awvalid,
--      s_axi_lite_wvalid  => s_axi_lite_wvalid,
--      s_axi_lite_wdata   => s_axi_lite_wdata,
--      s_axi_lite_bready  => s_axi_lite_bready,
--      m00_axi_awid       => m00_axi_awid,
--      m00_axi_awaddr     => m00_axi_awaddr,
--      m00_axi_awlen      => m00_axi_awlen,
--      m00_axi_awsize     => m00_axi_awsize,
--      m00_axi_awburst    => m00_axi_awburst,
--      m00_axi_awlock     => m00_axi_awlock,
--      m00_axi_awcache    => m00_axi_awcache,
--      m00_axi_awprot     => m00_axi_awprot,
--      m00_axi_awqos      => m00_axi_awqos,
--      m00_axi_awuser     => m00_axi_awuser,
--      m00_axi_awvalid    => m00_axi_awvalid,
--      m00_axi_wdata      => m00_axi_wdata,
--      m00_axi_wstrb      => m00_axi_wstrb,
--      m00_axi_wlast      => m00_axi_wlast,
--      m00_axi_wuser      => m00_axi_wuser,
--      m00_axi_wvalid     => m00_axi_wvalid,
--      m00_axi_bready     => m00_axi_bready,
--      fifo_full          => fifo_full,
--      s_axi_lite_arready => s_axi_lite_arready,
--      s_axi_lite_rvalid  => s_axi_lite_rvalid,
--      s_axi_lite_rdata   => s_axi_lite_rdata,
--      s_axi_lite_awready => s_axi_lite_awready,
--      s_axi_lite_wready  => s_axi_lite_wready,
--      s_axi_lite_bvalid  => s_axi_lite_bvalid,
--      dma_irq            => dma_irq
--      );

end Behavioral;
