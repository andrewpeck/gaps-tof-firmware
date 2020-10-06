library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GAPS_DMA_Controller_rev1_v1_0 is
	generic (
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 6; 
	    C_S01_AXI_DATA_WIDTH	: integer	:= 32;
		C_S01_AXI_ADDR_WIDTH	: integer	:= 32;
        words_to_send           : integer := 16;
        MAX_ADDRESS             : std_logic_vector(31 downto 0)  := x"1080_00000";
        HEAD                    : std_logic_vector (15 downto 0) := x"AAAA";
        TAIL                    : std_logic_vector (15 downto 0) := x"5555"
		
	);
	port (
	
        CLK_IN          : in std_logic;
        RST_IN          : in std_logic;
        fifo_in        : in std_logic_vector(31 downto 0);
        fifo_wr_en      : in std_logic;
        fifo_full       : out std_logic;

		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
		
        m_axi_s2mm_awid            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_awaddr          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_s2mm_awlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_s2mm_awsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_s2mm_awburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_s2mm_awprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_s2mm_awcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_awuser          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_awvalid         : OUT STD_LOGIC;
        m_axi_s2mm_awready         : IN STD_LOGIC;
        m_axi_s2mm_wdata           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_s2mm_wstrb           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_s2mm_wlast           : OUT STD_LOGIC;
        m_axi_s2mm_wvalid          : OUT STD_LOGIC;
        m_axi_s2mm_wready          : IN STD_LOGIC;
        m_axi_s2mm_bresp           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_s2mm_bvalid          : IN STD_LOGIC;
        m_axi_s2mm_bready          : OUT STD_LOGIC;
        
        
        m_axi_mm2s_arid           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_mm2s_araddr          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_mm2s_arlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m_axi_mm2s_arsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_mm2s_arburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_mm2s_arprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m_axi_mm2s_arcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_mm2s_aruser          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m_axi_mm2s_arvalid         : OUT STD_LOGIC;
        m_axi_mm2s_arready         : IN STD_LOGIC;
        m_axi_mm2s_rdata           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axi_mm2s_rresp           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
        m_axi_mm2s_rlast           : IN STD_LOGIC;
        m_axi_mm2s_rvalid          : IN STD_LOGIC;        
        m_axi_mm2s_rready          : OUT STD_LOGIC
     
		 
	);
end GAPS_DMA_Controller_rev1_v1_0;

architecture arch_imp of GAPS_DMA_Controller_rev1_v1_0 is

	-- component declaration
	component GAPS_DMA_Controller_rev1_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 6
		);
		port (
		S_AXI_ACLK	    : in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
        DMA_reg0        : in std_logic_vector(31 downto 0);
        DMA_reg1        : out std_logic_vector(31 downto 0);
        DMA_reg2        : out std_logic_vector(31 downto 0);
        DMA_reg3        : out std_logic_vector(31 downto 0);
        DMA_reg4        : out std_logic_vector(31 downto 0);
        DMA_reg5        : out std_logic_vector(31 downto 0)
		);
	end component GAPS_DMA_Controller_rev1_v1_0_S00_AXI;
    
    component dma_controller is
       Port ( 
            CLK_IN                     : in std_logic;
            CLK_AXI                    : in std_logic;
            RST_IN                     : in std_logic;
            
            fifo_in                    : in std_logic_vector(31 downto 0);
            fifo_wr_en                 : in std_logic;
            fifo_full                  : out std_logic;
 
            m_axi_s2mm_awid            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_s2mm_awaddr          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axi_s2mm_awlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            m_axi_s2mm_awsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m_axi_s2mm_awburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axi_s2mm_awprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m_axi_s2mm_awcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_s2mm_awuser          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_s2mm_awvalid         : OUT STD_LOGIC;
            m_axi_s2mm_awready         : IN STD_LOGIC;
            m_axi_s2mm_wdata           : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axi_s2mm_wstrb           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_s2mm_wlast           : OUT STD_LOGIC;
            m_axi_s2mm_wvalid          : OUT STD_LOGIC;
            m_axi_s2mm_wready          : IN STD_LOGIC;
            m_axi_s2mm_bresp           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axi_s2mm_bvalid          : IN STD_LOGIC;
            
            m_axi_s2mm_bready          : OUT STD_LOGIC;
            m_axi_mm2s_arid            : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_mm2s_araddr          : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axi_mm2s_arlen           : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            m_axi_mm2s_arsize          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m_axi_mm2s_arburst         : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axi_mm2s_arprot          : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m_axi_mm2s_arcache         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_mm2s_aruser          : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m_axi_mm2s_arvalid         : OUT STD_LOGIC;
            m_axi_mm2s_arready         : IN STD_LOGIC;
            m_axi_mm2s_rdata           : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            m_axi_mm2s_rresp           : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            m_axi_mm2s_rlast           : IN STD_LOGIC;
            m_axi_mm2s_rvalid          : IN STD_LOGIC;
            m_axi_mm2s_rready          : OUT STD_LOGIC;

            DMA_reg0                   : out std_logic_vector(31 downto 0);
            DMA_reg1                   : in std_logic_vector(31 downto 0);
            DMA_reg2                   : in std_logic_vector(31 downto 0);
            DMA_reg3                   : in std_logic_vector(31 downto 0);
            DMA_reg4                   : in std_logic_vector(31 downto 0);
            DMA_reg5                   : in std_logic_vector(31 downto 0)
       
       );
end component;
------------------------------------------------------------
-- DMA Registers
--- reg0:   packet tracker(increments when tail is present).   
--  reg1:   bit 0 = reset. 
--  reg2-5: RSVD
------------------------------------------------------------
signal DMA_reg0            :  std_logic_vector(31 downto 0);
signal DMA_reg1            :  std_logic_vector(31 downto 0);
signal DMA_reg2            :  std_logic_vector(31 downto 0);
signal DMA_reg3            :  std_logic_vector(31 downto 0);
signal DMA_reg4            :  std_logic_vector(31 downto 0);
signal DMA_reg5            :  std_logic_vector(31 downto 0);

begin

--AXI Lite Registers 
GAPS_DMA_Controller_rev1_v1_0_S00_AXI_inst : GAPS_DMA_Controller_rev1_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		S_AXI_ACLK	    => s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready,
        DMA_reg0        => DMA_reg0,
        DMA_reg1        => DMA_reg1,
        DMA_reg2        => DMA_reg2,
        DMA_reg3        => DMA_reg3,
        DMA_reg4        => DMA_reg4,
        DMA_reg5        => DMA_reg5
	);
	
dma_ctrl_inst: dma_controller  
   Port map( 
        CLK_IN              => CLK_IN,
        CLK_AXI             => s00_axi_aclk,
        RST_IN              => RST_IN,
         fifo_in            => fifo_in,
        fifo_wr_en          => fifo_wr_en,
        fifo_full           => fifo_full, 
        
        m_axi_s2mm_awid     => m_axi_s2mm_awid,
        m_axi_s2mm_awaddr   => m_axi_s2mm_awaddr,
        m_axi_s2mm_awlen    => m_axi_s2mm_awlen,
        m_axi_s2mm_awsize   => m_axi_s2mm_awsize,
        m_axi_s2mm_awburst  => m_axi_s2mm_awburst,
        m_axi_s2mm_awprot   => m_axi_s2mm_awprot,
        m_axi_s2mm_awcache  => m_axi_s2mm_awcache,
        m_axi_s2mm_awuser   => m_axi_s2mm_awuser,
        m_axi_s2mm_awvalid  => m_axi_s2mm_awvalid,
        m_axi_s2mm_awready  => m_axi_s2mm_awready,
        m_axi_s2mm_wdata    => m_axi_s2mm_wdata,
        m_axi_s2mm_wstrb    => m_axi_s2mm_wstrb,
        m_axi_s2mm_wlast    => m_axi_s2mm_wlast,
        m_axi_s2mm_wvalid   => m_axi_s2mm_wvalid,
        m_axi_s2mm_wready   => m_axi_s2mm_wready,
        m_axi_s2mm_bresp    => m_axi_s2mm_bresp,
        m_axi_s2mm_bvalid   => m_axi_s2mm_bvalid,
         m_axi_s2mm_bready  => m_axi_s2mm_bready, 
 
        m_axi_mm2s_arid     => m_axi_mm2s_arid,
        m_axi_mm2s_araddr   => m_axi_mm2s_araddr,
        m_axi_mm2s_arlen    => m_axi_mm2s_arlen,
        m_axi_mm2s_arsize   => m_axi_mm2s_arsize,
        m_axi_mm2s_arburst  => m_axi_mm2s_arburst,
        m_axi_mm2s_arprot   => m_axi_mm2s_arprot,
        m_axi_mm2s_arcache  => m_axi_mm2s_arcache,
        m_axi_mm2s_aruser   => m_axi_mm2s_aruser,
        m_axi_mm2s_arvalid  => m_axi_mm2s_arvalid,
        m_axi_mm2s_arready  => m_axi_mm2s_arready,
        m_axi_mm2s_rdata    => m_axi_mm2s_rdata,
        m_axi_mm2s_rresp    => m_axi_mm2s_rresp,
        m_axi_mm2s_rlast    => m_axi_mm2s_rlast,
        m_axi_mm2s_rvalid   => m_axi_mm2s_rvalid,
        m_axi_mm2s_rready   => m_axi_mm2s_rready,
        DMA_reg0            => DMA_reg0,
        DMA_reg1            => DMA_reg1,
        DMA_reg2            => DMA_reg2,
        DMA_reg3            => DMA_reg3,
        DMA_reg4            => DMA_reg4,
        DMA_reg5            => DMA_reg5
   );
 

end arch_imp;
