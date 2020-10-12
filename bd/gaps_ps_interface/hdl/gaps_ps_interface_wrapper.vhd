--Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2019.2.1 (lin64) Build 2729669 Thu Dec  5 04:48:12 MST 2019
--Date        : Mon Oct 12 15:20:50 2020
--Host        : larry running 64-bit Ubuntu 18.04.4 LTS
--Command     : generate_target gaps_ps_interface_wrapper.bd
--Design      : gaps_ps_interface_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity gaps_ps_interface_wrapper is
  port (
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DMA_AXI_ARESETN : out STD_LOGIC_VECTOR ( 0 to 0 );
    DMA_AXI_CLK_O : out STD_LOGIC;
    DMA_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_arlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arready : in STD_LOGIC;
    DMA_AXI_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_arvalid : out STD_LOGIC;
    DMA_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_awlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awready : in STD_LOGIC;
    DMA_AXI_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_awvalid : out STD_LOGIC;
    DMA_AXI_bid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_bready : out STD_LOGIC;
    DMA_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_bvalid : in STD_LOGIC;
    DMA_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_rid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_rlast : in STD_LOGIC;
    DMA_AXI_rready : out STD_LOGIC;
    DMA_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_rvalid : in STD_LOGIC;
    DMA_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_wid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_wlast : out STD_LOGIC;
    DMA_AXI_wready : in STD_LOGIC;
    DMA_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_wvalid : out STD_LOGIC;
    DMA_HP_AXI_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arready : out STD_LOGIC;
    DMA_HP_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_arvalid : in STD_LOGIC;
    DMA_HP_AXI_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awready : out STD_LOGIC;
    DMA_HP_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_awvalid : in STD_LOGIC;
    DMA_HP_AXI_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_bready : in STD_LOGIC;
    DMA_HP_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_bvalid : out STD_LOGIC;
    DMA_HP_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_rlast : out STD_LOGIC;
    DMA_HP_AXI_rready : in STD_LOGIC;
    DMA_HP_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_rvalid : out STD_LOGIC;
    DMA_HP_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_wid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_wlast : in STD_LOGIC;
    DMA_HP_AXI_wready : out STD_LOGIC;
    DMA_HP_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_wvalid : in STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    IPB_AXI_ARESETN : out STD_LOGIC_VECTOR ( 0 to 0 );
    IPB_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_arlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arready : in STD_LOGIC;
    IPB_AXI_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_arvalid : out STD_LOGIC;
    IPB_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_awlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awready : in STD_LOGIC;
    IPB_AXI_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_awvalid : out STD_LOGIC;
    IPB_AXI_bid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_bready : out STD_LOGIC;
    IPB_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_bvalid : in STD_LOGIC;
    IPB_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_rid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_rlast : in STD_LOGIC;
    IPB_AXI_rready : out STD_LOGIC;
    IPB_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_rvalid : in STD_LOGIC;
    IPB_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_wid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_wlast : out STD_LOGIC;
    IPB_AXI_wready : in STD_LOGIC;
    IPB_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_wvalid : out STD_LOGIC;
    IPB_MCLK_IN : in STD_LOGIC;
    IRQ_F2P_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    PL_MMCM_LOCKED : in STD_LOGIC
  );
end gaps_ps_interface_wrapper;

architecture STRUCTURE of gaps_ps_interface_wrapper is
  component gaps_ps_interface is
  port (
    IRQ_F2P_0 : in STD_LOGIC_VECTOR ( 0 to 0 );
    IPB_AXI_ARESETN : out STD_LOGIC_VECTOR ( 0 to 0 );
    DMA_AXI_ARESETN : out STD_LOGIC_VECTOR ( 0 to 0 );
    IPB_MCLK_IN : in STD_LOGIC;
    DMA_AXI_CLK_O : out STD_LOGIC;
    PL_MMCM_LOCKED : in STD_LOGIC;
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arvalid : out STD_LOGIC;
    DMA_AXI_awvalid : out STD_LOGIC;
    DMA_AXI_bready : out STD_LOGIC;
    DMA_AXI_rready : out STD_LOGIC;
    DMA_AXI_wlast : out STD_LOGIC;
    DMA_AXI_wvalid : out STD_LOGIC;
    DMA_AXI_arid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_awid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_wid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_AXI_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_AXI_arready : in STD_LOGIC;
    DMA_AXI_awready : in STD_LOGIC;
    DMA_AXI_bvalid : in STD_LOGIC;
    DMA_AXI_rlast : in STD_LOGIC;
    DMA_AXI_rvalid : in STD_LOGIC;
    DMA_AXI_wready : in STD_LOGIC;
    DMA_AXI_bid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_rid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    DMA_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_awid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_awaddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_awlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_awburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_awlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_awcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_awqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_awvalid : out STD_LOGIC;
    IPB_AXI_awready : in STD_LOGIC;
    IPB_AXI_wid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_wdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_wstrb : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_wlast : out STD_LOGIC;
    IPB_AXI_wvalid : out STD_LOGIC;
    IPB_AXI_wready : in STD_LOGIC;
    IPB_AXI_bid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_bresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_bvalid : in STD_LOGIC;
    IPB_AXI_bready : out STD_LOGIC;
    IPB_AXI_arid : out STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_araddr : out STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_arlen : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arsize : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_arburst : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_arlock : out STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_arcache : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arprot : out STD_LOGIC_VECTOR ( 2 downto 0 );
    IPB_AXI_arqos : out STD_LOGIC_VECTOR ( 3 downto 0 );
    IPB_AXI_arvalid : out STD_LOGIC;
    IPB_AXI_arready : in STD_LOGIC;
    IPB_AXI_rid : in STD_LOGIC_VECTOR ( 11 downto 0 );
    IPB_AXI_rdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    IPB_AXI_rresp : in STD_LOGIC_VECTOR ( 1 downto 0 );
    IPB_AXI_rlast : in STD_LOGIC;
    IPB_AXI_rvalid : in STD_LOGIC;
    IPB_AXI_rready : out STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    DMA_HP_AXI_arready : out STD_LOGIC;
    DMA_HP_AXI_awready : out STD_LOGIC;
    DMA_HP_AXI_bvalid : out STD_LOGIC;
    DMA_HP_AXI_rlast : out STD_LOGIC;
    DMA_HP_AXI_rvalid : out STD_LOGIC;
    DMA_HP_AXI_wready : out STD_LOGIC;
    DMA_HP_AXI_bresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_rresp : out STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_bid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_rid : out STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_rdata : out STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_arvalid : in STD_LOGIC;
    DMA_HP_AXI_awvalid : in STD_LOGIC;
    DMA_HP_AXI_bready : in STD_LOGIC;
    DMA_HP_AXI_rready : in STD_LOGIC;
    DMA_HP_AXI_wlast : in STD_LOGIC;
    DMA_HP_AXI_wvalid : in STD_LOGIC;
    DMA_HP_AXI_arburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_arlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_arsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_awburst : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_awlock : in STD_LOGIC_VECTOR ( 1 downto 0 );
    DMA_HP_AXI_awsize : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_arprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_awprot : in STD_LOGIC_VECTOR ( 2 downto 0 );
    DMA_HP_AXI_araddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_awaddr : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_arcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awcache : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awlen : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_awqos : in STD_LOGIC_VECTOR ( 3 downto 0 );
    DMA_HP_AXI_arid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_awid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_wid : in STD_LOGIC_VECTOR ( 5 downto 0 );
    DMA_HP_AXI_wdata : in STD_LOGIC_VECTOR ( 31 downto 0 );
    DMA_HP_AXI_wstrb : in STD_LOGIC_VECTOR ( 3 downto 0 )
  );
  end component gaps_ps_interface;
begin
gaps_ps_interface_i: component gaps_ps_interface
     port map (
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      DMA_AXI_ARESETN(0) => DMA_AXI_ARESETN(0),
      DMA_AXI_CLK_O => DMA_AXI_CLK_O,
      DMA_AXI_araddr(31 downto 0) => DMA_AXI_araddr(31 downto 0),
      DMA_AXI_arburst(1 downto 0) => DMA_AXI_arburst(1 downto 0),
      DMA_AXI_arcache(3 downto 0) => DMA_AXI_arcache(3 downto 0),
      DMA_AXI_arid(11 downto 0) => DMA_AXI_arid(11 downto 0),
      DMA_AXI_arlen(3 downto 0) => DMA_AXI_arlen(3 downto 0),
      DMA_AXI_arlock(1 downto 0) => DMA_AXI_arlock(1 downto 0),
      DMA_AXI_arprot(2 downto 0) => DMA_AXI_arprot(2 downto 0),
      DMA_AXI_arqos(3 downto 0) => DMA_AXI_arqos(3 downto 0),
      DMA_AXI_arready => DMA_AXI_arready,
      DMA_AXI_arsize(2 downto 0) => DMA_AXI_arsize(2 downto 0),
      DMA_AXI_arvalid => DMA_AXI_arvalid,
      DMA_AXI_awaddr(31 downto 0) => DMA_AXI_awaddr(31 downto 0),
      DMA_AXI_awburst(1 downto 0) => DMA_AXI_awburst(1 downto 0),
      DMA_AXI_awcache(3 downto 0) => DMA_AXI_awcache(3 downto 0),
      DMA_AXI_awid(11 downto 0) => DMA_AXI_awid(11 downto 0),
      DMA_AXI_awlen(3 downto 0) => DMA_AXI_awlen(3 downto 0),
      DMA_AXI_awlock(1 downto 0) => DMA_AXI_awlock(1 downto 0),
      DMA_AXI_awprot(2 downto 0) => DMA_AXI_awprot(2 downto 0),
      DMA_AXI_awqos(3 downto 0) => DMA_AXI_awqos(3 downto 0),
      DMA_AXI_awready => DMA_AXI_awready,
      DMA_AXI_awsize(2 downto 0) => DMA_AXI_awsize(2 downto 0),
      DMA_AXI_awvalid => DMA_AXI_awvalid,
      DMA_AXI_bid(11 downto 0) => DMA_AXI_bid(11 downto 0),
      DMA_AXI_bready => DMA_AXI_bready,
      DMA_AXI_bresp(1 downto 0) => DMA_AXI_bresp(1 downto 0),
      DMA_AXI_bvalid => DMA_AXI_bvalid,
      DMA_AXI_rdata(31 downto 0) => DMA_AXI_rdata(31 downto 0),
      DMA_AXI_rid(11 downto 0) => DMA_AXI_rid(11 downto 0),
      DMA_AXI_rlast => DMA_AXI_rlast,
      DMA_AXI_rready => DMA_AXI_rready,
      DMA_AXI_rresp(1 downto 0) => DMA_AXI_rresp(1 downto 0),
      DMA_AXI_rvalid => DMA_AXI_rvalid,
      DMA_AXI_wdata(31 downto 0) => DMA_AXI_wdata(31 downto 0),
      DMA_AXI_wid(11 downto 0) => DMA_AXI_wid(11 downto 0),
      DMA_AXI_wlast => DMA_AXI_wlast,
      DMA_AXI_wready => DMA_AXI_wready,
      DMA_AXI_wstrb(3 downto 0) => DMA_AXI_wstrb(3 downto 0),
      DMA_AXI_wvalid => DMA_AXI_wvalid,
      DMA_HP_AXI_araddr(31 downto 0) => DMA_HP_AXI_araddr(31 downto 0),
      DMA_HP_AXI_arburst(1 downto 0) => DMA_HP_AXI_arburst(1 downto 0),
      DMA_HP_AXI_arcache(3 downto 0) => DMA_HP_AXI_arcache(3 downto 0),
      DMA_HP_AXI_arid(5 downto 0) => DMA_HP_AXI_arid(5 downto 0),
      DMA_HP_AXI_arlen(3 downto 0) => DMA_HP_AXI_arlen(3 downto 0),
      DMA_HP_AXI_arlock(1 downto 0) => DMA_HP_AXI_arlock(1 downto 0),
      DMA_HP_AXI_arprot(2 downto 0) => DMA_HP_AXI_arprot(2 downto 0),
      DMA_HP_AXI_arqos(3 downto 0) => DMA_HP_AXI_arqos(3 downto 0),
      DMA_HP_AXI_arready => DMA_HP_AXI_arready,
      DMA_HP_AXI_arsize(2 downto 0) => DMA_HP_AXI_arsize(2 downto 0),
      DMA_HP_AXI_arvalid => DMA_HP_AXI_arvalid,
      DMA_HP_AXI_awaddr(31 downto 0) => DMA_HP_AXI_awaddr(31 downto 0),
      DMA_HP_AXI_awburst(1 downto 0) => DMA_HP_AXI_awburst(1 downto 0),
      DMA_HP_AXI_awcache(3 downto 0) => DMA_HP_AXI_awcache(3 downto 0),
      DMA_HP_AXI_awid(5 downto 0) => DMA_HP_AXI_awid(5 downto 0),
      DMA_HP_AXI_awlen(3 downto 0) => DMA_HP_AXI_awlen(3 downto 0),
      DMA_HP_AXI_awlock(1 downto 0) => DMA_HP_AXI_awlock(1 downto 0),
      DMA_HP_AXI_awprot(2 downto 0) => DMA_HP_AXI_awprot(2 downto 0),
      DMA_HP_AXI_awqos(3 downto 0) => DMA_HP_AXI_awqos(3 downto 0),
      DMA_HP_AXI_awready => DMA_HP_AXI_awready,
      DMA_HP_AXI_awsize(2 downto 0) => DMA_HP_AXI_awsize(2 downto 0),
      DMA_HP_AXI_awvalid => DMA_HP_AXI_awvalid,
      DMA_HP_AXI_bid(5 downto 0) => DMA_HP_AXI_bid(5 downto 0),
      DMA_HP_AXI_bready => DMA_HP_AXI_bready,
      DMA_HP_AXI_bresp(1 downto 0) => DMA_HP_AXI_bresp(1 downto 0),
      DMA_HP_AXI_bvalid => DMA_HP_AXI_bvalid,
      DMA_HP_AXI_rdata(31 downto 0) => DMA_HP_AXI_rdata(31 downto 0),
      DMA_HP_AXI_rid(5 downto 0) => DMA_HP_AXI_rid(5 downto 0),
      DMA_HP_AXI_rlast => DMA_HP_AXI_rlast,
      DMA_HP_AXI_rready => DMA_HP_AXI_rready,
      DMA_HP_AXI_rresp(1 downto 0) => DMA_HP_AXI_rresp(1 downto 0),
      DMA_HP_AXI_rvalid => DMA_HP_AXI_rvalid,
      DMA_HP_AXI_wdata(31 downto 0) => DMA_HP_AXI_wdata(31 downto 0),
      DMA_HP_AXI_wid(5 downto 0) => DMA_HP_AXI_wid(5 downto 0),
      DMA_HP_AXI_wlast => DMA_HP_AXI_wlast,
      DMA_HP_AXI_wready => DMA_HP_AXI_wready,
      DMA_HP_AXI_wstrb(3 downto 0) => DMA_HP_AXI_wstrb(3 downto 0),
      DMA_HP_AXI_wvalid => DMA_HP_AXI_wvalid,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      IPB_AXI_ARESETN(0) => IPB_AXI_ARESETN(0),
      IPB_AXI_araddr(31 downto 0) => IPB_AXI_araddr(31 downto 0),
      IPB_AXI_arburst(1 downto 0) => IPB_AXI_arburst(1 downto 0),
      IPB_AXI_arcache(3 downto 0) => IPB_AXI_arcache(3 downto 0),
      IPB_AXI_arid(11 downto 0) => IPB_AXI_arid(11 downto 0),
      IPB_AXI_arlen(3 downto 0) => IPB_AXI_arlen(3 downto 0),
      IPB_AXI_arlock(1 downto 0) => IPB_AXI_arlock(1 downto 0),
      IPB_AXI_arprot(2 downto 0) => IPB_AXI_arprot(2 downto 0),
      IPB_AXI_arqos(3 downto 0) => IPB_AXI_arqos(3 downto 0),
      IPB_AXI_arready => IPB_AXI_arready,
      IPB_AXI_arsize(2 downto 0) => IPB_AXI_arsize(2 downto 0),
      IPB_AXI_arvalid => IPB_AXI_arvalid,
      IPB_AXI_awaddr(31 downto 0) => IPB_AXI_awaddr(31 downto 0),
      IPB_AXI_awburst(1 downto 0) => IPB_AXI_awburst(1 downto 0),
      IPB_AXI_awcache(3 downto 0) => IPB_AXI_awcache(3 downto 0),
      IPB_AXI_awid(11 downto 0) => IPB_AXI_awid(11 downto 0),
      IPB_AXI_awlen(3 downto 0) => IPB_AXI_awlen(3 downto 0),
      IPB_AXI_awlock(1 downto 0) => IPB_AXI_awlock(1 downto 0),
      IPB_AXI_awprot(2 downto 0) => IPB_AXI_awprot(2 downto 0),
      IPB_AXI_awqos(3 downto 0) => IPB_AXI_awqos(3 downto 0),
      IPB_AXI_awready => IPB_AXI_awready,
      IPB_AXI_awsize(2 downto 0) => IPB_AXI_awsize(2 downto 0),
      IPB_AXI_awvalid => IPB_AXI_awvalid,
      IPB_AXI_bid(11 downto 0) => IPB_AXI_bid(11 downto 0),
      IPB_AXI_bready => IPB_AXI_bready,
      IPB_AXI_bresp(1 downto 0) => IPB_AXI_bresp(1 downto 0),
      IPB_AXI_bvalid => IPB_AXI_bvalid,
      IPB_AXI_rdata(31 downto 0) => IPB_AXI_rdata(31 downto 0),
      IPB_AXI_rid(11 downto 0) => IPB_AXI_rid(11 downto 0),
      IPB_AXI_rlast => IPB_AXI_rlast,
      IPB_AXI_rready => IPB_AXI_rready,
      IPB_AXI_rresp(1 downto 0) => IPB_AXI_rresp(1 downto 0),
      IPB_AXI_rvalid => IPB_AXI_rvalid,
      IPB_AXI_wdata(31 downto 0) => IPB_AXI_wdata(31 downto 0),
      IPB_AXI_wid(11 downto 0) => IPB_AXI_wid(11 downto 0),
      IPB_AXI_wlast => IPB_AXI_wlast,
      IPB_AXI_wready => IPB_AXI_wready,
      IPB_AXI_wstrb(3 downto 0) => IPB_AXI_wstrb(3 downto 0),
      IPB_AXI_wvalid => IPB_AXI_wvalid,
      IPB_MCLK_IN => IPB_MCLK_IN,
      IRQ_F2P_0(0) => IRQ_F2P_0(0),
      PL_MMCM_LOCKED => PL_MMCM_LOCKED
    );
end STRUCTURE;
