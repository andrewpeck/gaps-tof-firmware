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

    -- Top Level Pins
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

    -- From Logic
    fifo_data_in  : in std_logic_vector (15 downto 0);
    fifo_clock_in : in std_logic;
    fifo_data_wen : in std_logic;

    clk33          : in std_logic;
    pl_mmcm_locked : in std_logic;

    ipb_reset    : out std_logic;
    ipb_clk      : out std_logic;
    ipb_miso_arr : in  ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    ipb_mosi_arr : out ipb_wbus_array(IPB_SLAVES - 1 downto 0);

    dma_reset : in std_logic
    );

end ps_interface;

architecture Behavioral of ps_interface is

  signal dma_axi_aclk    : std_logic;
  signal dma_axi_aresetn : std_logic;
  signal dma_axi_araddr  : std_logic_vector (31 downto 0);
  signal dma_axi_arburst : std_logic_vector (1 downto 0);
  signal dma_axi_arcache : std_logic_vector (3 downto 0);
  signal dma_axi_arid    : std_logic_vector (11 downto 0);
  signal dma_axi_arlen   : std_logic_vector (3 downto 0);
  signal dma_axi_arlock  : std_logic_vector (1 downto 0);
  signal dma_axi_arprot  : std_logic_vector (2 downto 0);
  signal dma_axi_arqos   : std_logic_vector (3 downto 0);
  signal dma_axi_arready : std_logic;
  signal dma_axi_arsize  : std_logic_vector (2 downto 0);
  signal dma_axi_arvalid : std_logic;
  signal dma_axi_awaddr  : std_logic_vector (31 downto 0);
  signal dma_axi_awburst : std_logic_vector (1 downto 0);
  signal dma_axi_awcache : std_logic_vector (3 downto 0);
  signal dma_axi_awid    : std_logic_vector (11 downto 0);
  signal dma_axi_awlen   : std_logic_vector (3 downto 0);
  signal dma_axi_awlock  : std_logic_vector (1 downto 0);
  signal dma_axi_awprot  : std_logic_vector (2 downto 0);
  signal dma_axi_awqos   : std_logic_vector (3 downto 0);
  signal dma_axi_awready : std_logic;
  signal dma_axi_awsize  : std_logic_vector (2 downto 0);
  signal dma_axi_awvalid : std_logic;
  signal dma_axi_bid     : std_logic_vector (11 downto 0);
  signal dma_axi_bready  : std_logic;
  signal dma_axi_bresp   : std_logic_vector (1 downto 0);
  signal dma_axi_bvalid  : std_logic;
  signal dma_axi_rdata   : std_logic_vector (31 downto 0);
  signal dma_axi_rid     : std_logic_vector (11 downto 0);
  signal dma_axi_rlast   : std_logic;
  signal dma_axi_rready  : std_logic;
  signal dma_axi_rresp   : std_logic_vector (1 downto 0);
  signal dma_axi_rvalid  : std_logic;
  signal dma_axi_wdata   : std_logic_vector (31 downto 0);
  signal dma_axi_wid     : std_logic_vector (11 downto 0);
  signal dma_axi_wlast   : std_logic;
  signal dma_axi_wready  : std_logic;
  signal dma_axi_wstrb   : std_logic_vector (3 downto 0);
  signal dma_axi_wvalid  : std_logic;

  signal dma_hp_axi_araddr  : std_logic_vector (31 downto 0);
  signal dma_hp_axi_arburst : std_logic_vector (1 downto 0);
  signal dma_hp_axi_arcache : std_logic_vector (3 downto 0);
  signal dma_hp_axi_arid    : std_logic_vector (5 downto 0);
  signal dma_hp_axi_arlen   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_arlock  : std_logic_vector (1 downto 0);
  signal dma_hp_axi_arprot  : std_logic_vector (2 downto 0);
  signal dma_hp_axi_arqos   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_arready : std_logic;
  signal dma_hp_axi_arsize  : std_logic_vector (2 downto 0);
  signal dma_hp_axi_arvalid : std_logic;
  signal dma_hp_axi_awaddr  : std_logic_vector (31 downto 0);
  signal dma_hp_axi_awburst : std_logic_vector (1 downto 0);
  signal dma_hp_axi_awcache : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awuser  : std_logic_vector (3 downto 0);
  signal dma_hp_axi_aruser  : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awid    : std_logic_vector (5 downto 0);
  signal dma_hp_axi_awlen   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awlock  : std_logic_vector (1 downto 0);
  signal dma_hp_axi_awprot  : std_logic_vector (2 downto 0);
  signal dma_hp_axi_awqos   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awready : std_logic;
  signal dma_hp_axi_awsize  : std_logic_vector (2 downto 0);
  signal dma_hp_axi_awvalid : std_logic;
  signal dma_hp_axi_bid     : std_logic_vector (5 downto 0);
  signal dma_hp_axi_bready  : std_logic;
  signal dma_hp_axi_bresp   : std_logic_vector (1 downto 0);
  signal dma_hp_axi_bvalid  : std_logic;
  signal dma_hp_axi_rdata   : std_logic_vector (31 downto 0);
  signal dma_hp_axi_rid     : std_logic_vector (5 downto 0);
  signal dma_hp_axi_rlast   : std_logic;
  signal dma_hp_axi_rready  : std_logic;
  signal dma_hp_axi_rresp   : std_logic_vector (1 downto 0);
  signal dma_hp_axi_rvalid  : std_logic;
  signal dma_hp_axi_wdata   : std_logic_vector (31 downto 0);
  signal dma_hp_axi_wid     : std_logic_vector (5 downto 0);
  signal dma_hp_axi_wlast   : std_logic;
  signal dma_hp_axi_wready  : std_logic;
  signal dma_hp_axi_wstrb   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_wvalid  : std_logic;

  signal ipb_axi_aresetn : std_logic;
  signal ipb_axi_araddr  : std_logic_vector (31 downto 0);
  signal ipb_axi_arburst : std_logic_vector (1 downto 0);
  signal ipb_axi_arcache : std_logic_vector (3 downto 0);
  signal ipb_axi_arid    : std_logic_vector (11 downto 0);
  signal ipb_axi_arlen   : std_logic_vector (3 downto 0);
  signal ipb_axi_arlock  : std_logic_vector (1 downto 0);
  signal ipb_axi_arprot  : std_logic_vector (2 downto 0);
  signal ipb_axi_arqos   : std_logic_vector (3 downto 0);
  signal ipb_axi_arready : std_logic;
  signal ipb_axi_arsize  : std_logic_vector (2 downto 0);
  signal ipb_axi_arvalid : std_logic;
  signal ipb_axi_awaddr  : std_logic_vector (31 downto 0);
  signal ipb_axi_awburst : std_logic_vector (1 downto 0);
  signal ipb_axi_awcache : std_logic_vector (3 downto 0);
  signal ipb_axi_awid    : std_logic_vector (11 downto 0);
  signal ipb_axi_awlen   : std_logic_vector (3 downto 0);
  signal ipb_axi_awlock  : std_logic_vector (1 downto 0);
  signal ipb_axi_awprot  : std_logic_vector (2 downto 0);
  signal ipb_axi_awqos   : std_logic_vector (3 downto 0);
  signal ipb_axi_awready : std_logic;
  signal ipb_axi_awsize  : std_logic_vector (2 downto 0);
  signal ipb_axi_awvalid : std_logic;
  signal ipb_axi_bid     : std_logic_vector (11 downto 0);
  signal ipb_axi_bready  : std_logic;
  signal ipb_axi_bresp   : std_logic_vector (1 downto 0);
  signal ipb_axi_bvalid  : std_logic;
  signal ipb_axi_rdata   : std_logic_vector (31 downto 0);
  signal ipb_axi_rid     : std_logic_vector (11 downto 0);
  signal ipb_axi_rlast   : std_logic;
  signal ipb_axi_rready  : std_logic;
  signal ipb_axi_rresp   : std_logic_vector (1 downto 0);
  signal ipb_axi_rvalid  : std_logic;
  signal ipb_axi_wdata   : std_logic_vector (31 downto 0);
  signal ipb_axi_wid     : std_logic_vector (11 downto 0);
  signal ipb_axi_wlast   : std_logic;
  signal ipb_axi_wready  : std_logic;
  signal ipb_axi_wstrb   : std_logic_vector (3 downto 0);
  signal ipb_axi_wvalid  : std_logic;

  signal irq_f2p_0 : std_logic_vector (0 to 0) := (others => '0');

  -------------------------- AXI-IPbus bridge ---------------------------------

  --AXI
  signal axi_clk      : std_logic;
  signal ipb_axi_mosi : t_axi_lite_mosi;
  signal ipb_axi_miso : t_axi_lite_miso;

begin

  gaps_ps_interface_inst : entity work.gaps_ps_interface
    port map (

      dma_axi_clk_o  => dma_axi_aclk,   -- FIXME: connect this
      ipb_mclk_in    => clk33,
      pl_mmcm_locked => locked,

      --
      fixed_io_ddr_vrn  => fixed_io_ddr_vrn,
      fixed_io_ddr_vrp  => fixed_io_ddr_vrp,
      fixed_io_mio      => fixed_io_mio,
      fixed_io_ps_clk   => fixed_io_ps_clk,
      fixed_io_ps_porb  => fixed_io_ps_porb,
      fixed_io_ps_srstb => fixed_io_ps_srstb,

      --
      ddr_addr    => ddr_addr,
      ddr_ba      => ddr_ba,
      ddr_cas_n   => ddr_cas_n,
      ddr_ck_n    => ddr_ck_n,
      ddr_ck_p    => ddr_ck_p,
      ddr_cke     => ddr_cke,
      ddr_cs_n    => ddr_cs_n,
      ddr_dm      => ddr_dm,
      ddr_dq      => ddr_dq,
      ddr_dqs_n   => ddr_dqs_n,
      ddr_dqs_p   => ddr_dqs_p,
      ddr_odt     => ddr_odt,
      ddr_ras_n   => ddr_ras_n,
      ddr_reset_n => ddr_reset_n,
      ddr_we_n    => ddr_we_n,

      --
      dma_axi_aresetn => dma_axi_aresetn,
      dma_axi_araddr  => dma_axi_araddr,
      dma_axi_arburst => dma_axi_arburst,
      dma_axi_arcache => dma_axi_arcache,
      dma_axi_arid    => dma_axi_arid,
      dma_axi_arlen   => dma_axi_arlen,
      dma_axi_arlock  => dma_axi_arlock,
      dma_axi_arprot  => dma_axi_arprot,
      dma_axi_arqos   => dma_axi_arqos,
      dma_axi_arready => dma_axi_arready,
      dma_axi_arsize  => dma_axi_arsize,
      dma_axi_arvalid => dma_axi_arvalid,
      dma_axi_awaddr  => dma_axi_awaddr,
      dma_axi_awburst => dma_axi_awburst,
      dma_axi_awcache => dma_axi_awcache,
      dma_axi_awid    => dma_axi_awid,
      dma_axi_awlen   => dma_axi_awlen,
      dma_axi_awlock  => dma_axi_awlock,
      dma_axi_awprot  => dma_axi_awprot,
      dma_axi_awqos   => dma_axi_awqos,
      dma_axi_awready => dma_axi_awready,
      dma_axi_awsize  => dma_axi_awsize,
      dma_axi_awvalid => dma_axi_awvalid,
      dma_axi_bid     => dma_axi_bid,
      dma_axi_bready  => dma_axi_bready,
      dma_axi_bresp   => dma_axi_bresp,
      dma_axi_bvalid  => dma_axi_bvalid,
      dma_axi_rdata   => dma_axi_rdata,
      dma_axi_rid     => dma_axi_rid,
      dma_axi_rlast   => dma_axi_rlast,
      dma_axi_rready  => dma_axi_rready,
      dma_axi_rresp   => dma_axi_rresp,
      dma_axi_rvalid  => dma_axi_rvalid,
      dma_axi_wdata   => dma_axi_wdata,
      dma_axi_wid     => dma_axi_wid,
      dma_axi_wlast   => dma_axi_wlast,
      dma_axi_wready  => dma_axi_wready,
      dma_axi_wstrb   => dma_axi_wstrb,
      dma_axi_wvalid  => dma_axi_wvalid,

      --
      dma_hp_axi_araddr  => dma_hp_axi_araddr,
      dma_hp_axi_arburst => dma_hp_axi_arburst,
      dma_hp_axi_arcache => dma_hp_axi_arcache,
      dma_hp_axi_aruser  => dma_hp_axi_aruser,
      dma_hp_axi_awuser  => dma_hp_axi_awuser,
      dma_hp_axi_arid    => dma_hp_axi_arid,
      dma_hp_axi_arlen   => dma_hp_axi_arlen,
      dma_hp_axi_arlock  => dma_hp_axi_arlock,
      dma_hp_axi_arprot  => dma_hp_axi_arprot,
      dma_hp_axi_arqos   => dma_hp_axi_arqos,
      dma_hp_axi_arready => dma_hp_axi_arready,
      dma_hp_axi_arsize  => dma_hp_axi_arsize,
      dma_hp_axi_arvalid => dma_hp_axi_arvalid,
      dma_hp_axi_awaddr  => dma_hp_axi_awaddr,
      dma_hp_axi_awburst => dma_hp_axi_awburst,
      dma_hp_axi_awcache => dma_hp_axi_awcache,
      dma_hp_axi_awid    => dma_hp_axi_awid,
      dma_hp_axi_awlen   => dma_hp_axi_awlen,
      dma_hp_axi_awlock  => dma_hp_axi_awlock,
      dma_hp_axi_awprot  => dma_hp_axi_awprot,
      dma_hp_axi_awqos   => dma_hp_axi_awqos,
      dma_hp_axi_awready => dma_hp_axi_awready,
      dma_hp_axi_awsize  => dma_hp_axi_awsize,
      dma_hp_axi_awvalid => dma_hp_axi_awvalid,
      dma_hp_axi_bid     => dma_hp_axi_bid,
      dma_hp_axi_bready  => dma_hp_axi_bready,
      dma_hp_axi_bresp   => dma_hp_axi_bresp,
      dma_hp_axi_bvalid  => dma_hp_axi_bvalid,
      dma_hp_axi_rdata   => dma_hp_axi_rdata,
      dma_hp_axi_rid     => dma_hp_axi_rid,
      dma_hp_axi_rlast   => dma_hp_axi_rlast,
      dma_hp_axi_rready  => dma_hp_axi_rready,
      dma_hp_axi_rresp   => dma_hp_axi_rresp,
      dma_hp_axi_rvalid  => dma_hp_axi_rvalid,
      dma_hp_axi_wdata   => dma_hp_axi_wdata,
      dma_hp_axi_wid     => dma_hp_axi_wid,
      dma_hp_axi_wlast   => dma_hp_axi_wlast,
      dma_hp_axi_wready  => dma_hp_axi_wready,
      dma_hp_axi_wstrb   => dma_hp_axi_wstrb,
      dma_hp_axi_wvalid  => dma_hp_axi_wvalid,

      --
      ipb_axi_aresetn => ipb_axi_aresetn,
      ipb_axi_araddr  => ipb_axi_araddr,
      ipb_axi_arburst => ipb_axi_arburst,
      ipb_axi_arcache => ipb_axi_arcache,
      ipb_axi_arid    => ipb_axi_arid,
      ipb_axi_arlen   => ipb_axi_arlen,
      ipb_axi_arlock  => ipb_axi_arlock,
      ipb_axi_arprot  => ipb_axi_arprot,
      ipb_axi_arqos   => ipb_axi_arqos,
      ipb_axi_arready => ipb_axi_arready,
      ipb_axi_arsize  => ipb_axi_arsize,
      ipb_axi_arvalid => ipb_axi_arvalid,
      ipb_axi_awaddr  => ipb_axi_awaddr,
      ipb_axi_awburst => ipb_axi_awburst,
      ipb_axi_awcache => ipb_axi_awcache,
      ipb_axi_awid    => ipb_axi_awid,
      ipb_axi_awlen   => ipb_axi_awlen,
      ipb_axi_awlock  => ipb_axi_awlock,
      ipb_axi_awprot  => ipb_axi_awprot,
      ipb_axi_awqos   => ipb_axi_awqos,
      ipb_axi_awready => ipb_axi_awready,
      ipb_axi_awsize  => ipb_axi_awsize,
      ipb_axi_awvalid => ipb_axi_awvalid,
      ipb_axi_bid     => ipb_axi_bid,
      ipb_axi_bready  => ipb_axi_bready,
      ipb_axi_bresp   => ipb_axi_bresp,
      ipb_axi_bvalid  => ipb_axi_bvalid,
      ipb_axi_rdata   => ipb_axi_rdata,
      ipb_axi_rid     => ipb_axi_rid,
      ipb_axi_rlast   => ipb_axi_rlast,
      ipb_axi_rready  => ipb_axi_rready,
      ipb_axi_rresp   => ipb_axi_rresp,
      ipb_axi_rvalid  => ipb_axi_rvalid,
      ipb_axi_wdata   => ipb_axi_wdata,
      ipb_axi_wid     => ipb_axi_wid,
      ipb_axi_wlast   => ipb_axi_wlast,
      ipb_axi_wready  => ipb_axi_wready,
      ipb_axi_wstrb   => ipb_axi_wstrb,
      ipb_axi_wvalid  => ipb_axi_wvalid,
      irq_f2p_0       => irq_f2p_0);

  gaps_dma_controller_rev1_v1_0_1 : entity dma.gaps_dma_controller_rev1_v1_0
    --generic map (
    --  c_s00_axi_data_width => 32,
    --  c_s00_axi_addr_width => 32,
    --  c_s01_axi_data_width => 32,
    --  c_s01_axi_addr_width => 32,
    --  words_to_send        => words_to_send,
    --  max_address          => 16,
    --  head                 => head,
    --  tail                 => tail
    --  )
    port map (

      clk_in     => fifo_clock_in,
      rst_in     => dma_reset,
      fifo_in    => fifo_data_in,
      fifo_wr_en => fifo_data_wen,
      fifo_full  => open,               -- TODO: connect to monitor

      s00_axi_aclk    => dma_axi_aclk,
      s00_axi_aresetn => dma_axi_aresetn,
      s00_axi_awaddr  => dma_axi_awaddr,
      s00_axi_awprot  => dma_axi_awprot,
      s00_axi_awvalid => dma_axi_awvalid,
      s00_axi_awready => dma_axi_awready,
      s00_axi_wdata   => dma_axi_wdata,
      s00_axi_wstrb   => dma_axi_wstrb,
      s00_axi_wvalid  => dma_axi_wvalid,
      s00_axi_wready  => dma_axi_wready,
      s00_axi_bresp   => dma_axi_bresp,
      s00_axi_bvalid  => dma_axi_bvalid,
      s00_axi_bready  => dma_axi_bready,
      s00_axi_araddr  => dma_axi_araddr,
      s00_axi_arprot  => dma_axi_arprot,
      s00_axi_arvalid => dma_axi_arvalid,
      s00_axi_arready => dma_axi_arready,
      s00_axi_rdata   => dma_axi_rdata,
      s00_axi_rresp   => dma_axi_rresp,
      s00_axi_rvalid  => dma_axi_rvalid,
      s00_axi_rready  => dma_axi_rready,

      m_axi_s2mm_awid    => dma_hp_axi_awid,
      m_axi_s2mm_awaddr  => dma_hp_axi_awaddr,
      m_axi_s2mm_awlen   => dma_hp_axi_awlen,
      m_axi_s2mm_awsize  => dma_hp_axi_awsize,
      m_axi_s2mm_awburst => dma_hp_axi_awburst,
      m_axi_s2mm_awprot  => dma_hp_axi_awprot,
      m_axi_s2mm_awcache => dma_hp_axi_awcache,
      m_axi_s2mm_awuser  => dma_hp_axi_awuser,
      m_axi_s2mm_awvalid => dma_hp_axi_awvalid,
      m_axi_s2mm_awready => dma_hp_axi_awready,
      m_axi_s2mm_wdata   => dma_hp_axi_wdata,
      m_axi_s2mm_wstrb   => dma_hp_axi_wstrb,
      m_axi_s2mm_wlast   => dma_hp_axi_wlast,
      m_axi_s2mm_wvalid  => dma_hp_axi_wvalid,
      m_axi_s2mm_wready  => dma_hp_axi_wready,
      m_axi_s2mm_bresp   => dma_hp_axi_bresp,
      m_axi_s2mm_bvalid  => dma_hp_axi_bvalid,
      m_axi_s2mm_bready  => dma_hp_axi_bready,
      m_axi_mm2s_arid    => dma_hp_axi_arid,
      m_axi_mm2s_araddr  => dma_hp_axi_araddr,
      m_axi_mm2s_arlen   => dma_hp_axi_arlen,
      m_axi_mm2s_arsize  => dma_hp_axi_arsize,
      m_axi_mm2s_arburst => dma_hp_axi_arburst,
      m_axi_mm2s_arprot  => dma_hp_axi_arprot,
      m_axi_mm2s_arcache => dma_hp_axi_arcache,
      m_axi_mm2s_aruser  => dma_hp_axi_aruser,
      m_axi_mm2s_arvalid => dma_hp_axi_arvalid,
      m_axi_mm2s_arready => dma_hp_axi_arready,
      m_axi_mm2s_rdata   => dma_hp_axi_rdata,
      m_axi_mm2s_rresp   => dma_hp_axi_rresp,
      m_axi_mm2s_rlast   => dma_hp_axi_rlast,
      m_axi_mm2s_rvalid  => dma_hp_axi_rvalid,
      m_axi_mm2s_rready  => dma_hp_axi_rready
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
      S_AXI_ACLK    => clk33,
      S_AXI_ARESETN => ipb_axi_aresetn,
      S_AXI_ARADDR  => ipb_axi_araddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
      S_AXI_ARPROT  => ipb_axi_arprot,
      S_AXI_ARREADY => ipb_axi_arready,
      S_AXI_ARVALID => ipb_axi_arvalid,
      S_AXI_AWADDR  => ipb_axi_awaddr(C_IPB_AXI_ADDR_WIDTH - 1 downto 0),
      S_AXI_AWPROT  => ipb_axi_awprot,
      S_AXI_AWREADY => ipb_axi_awready,
      S_AXI_AWVALID => ipb_axi_awvalid,
      S_AXI_BREADY  => ipb_axi_bready,
      S_AXI_BRESP   => ipb_axi_bresp,
      S_AXI_BVALID  => ipb_axi_bvalid,
      S_AXI_RDATA   => ipb_axi_rdata,
      S_AXI_RRESP   => ipb_axi_rresp,
      S_AXI_RVALID  => ipb_axi_rvalid,
      S_AXI_WDATA   => ipb_axi_wdata,
      S_AXI_WREADY  => ipb_axi_wready,
      S_AXI_WVALID  => ipb_axi_wvalid,
      S_AXI_WSTRB   => ipb_axi_wstrb,
      S_AXI_RREADY  => ipb_axi_rready
      );



end Behavioral;
