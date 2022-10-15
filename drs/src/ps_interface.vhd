library xpm;
use xpm.vcomponents.all;

library work;
use work.ipbus.all;
use work.registers.all;
use work.types_pkg.all;
use work.axi_pkg.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

library xil_defaultlib;

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
    emio_scl          : inout std_logic;
    emio_sda          : inout std_logic;

    -- From Logic
    fifo_data_in  : in std_logic_vector (15 downto 0);
    fifo_clock_in : in std_logic;
    fifo_data_wen : in std_logic;
    
    daq_busy_in   : in std_logic;

    clk33          : in std_logic;
    pl_mmcm_locked : in std_logic;

    packet_counter      : out std_logic_vector(31 downto 0);
    dma_control_reset_i : in  std_logic;
    dma_clear_i         : in  std_logic;

    ipb_reset    : out std_logic;
    ipb_clk      : out std_logic;
    ipb_miso_arr : in  ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
    ipb_mosi_arr : out ipb_wbus_array(IPB_SLAVES - 1 downto 0);


    --DMA 
    dma_reset_i : in std_logic;
    
    
    --------------------------------------------------------------
    -- RAM Occupancy signals
    --------------------------------------------------------------
    ram_a_occ_rst_i  : in std_logic;
    ram_b_occ_rst_i  : in std_logic;

    ram_toggle_request_i : in std_logic := '0';

    ram_buff_a_occupancy_o  : out std_logic_vector(31 downto 0) := (others => '0');
    ram_buff_b_occupancy_o  : out std_logic_vector(31 downto 0) := (others => '0');
    dma_pointer_o           : out std_logic_vector(31 downto 0)
    
    );

end ps_interface;

architecture Behavioral of ps_interface is

  constant EN_TMR_IPB_SLAVE_PS : integer := 0;

  signal packet_counter_xdma : std_logic_vector (31 downto 0);

  signal dma_reset                : std_logic;
  signal dma_reset_synced         : std_logic;
  signal dma_control_reset        : std_logic;
  signal dma_control_reset_ext    : std_logic;
  signal dma_clear_ext            : std_logic := '0';
  signal dma_clear                : std_logic;

  signal ipb_reset_async      : std_logic := '0';
  signal ipb_axi_aresetn_sync : std_logic := '0';

  signal dma_axi_aclk    : std_logic;

  signal dma_hp_axi_araddr   : std_logic_vector (31 downto 0);
  signal dma_hp_axi_arburst  : std_logic_vector (1 downto 0);
  signal dma_hp_axi_arcache  : std_logic_vector (3 downto 0);
  signal dma_hp_axi_arid     : std_logic_vector (5 downto 0);
  signal dma_hp_axi_arlen    : std_logic_vector (7 downto 0);
  signal dma_hp_axi_arlock   : std_logic_vector (1 downto 0);
  signal dma_hp_axi_arprot   : std_logic_vector (2 downto 0);
  signal dma_hp_axi_arqos    : std_logic_vector (3 downto 0);
  signal dma_hp_axi_arready  : std_logic;
  signal dma_hp_axi_arsize   : std_logic_vector (2 downto 0);
  signal dma_hp_axi_arvalid  : std_logic;
  signal dma_hp_axi_awaddr   : std_logic_vector (31 downto 0);
  signal dma_hp_axi_awburst  : std_logic_vector (1 downto 0);
  signal dma_hp_axi_awcache  : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awuser   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_aruser   : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awid     : std_logic_vector (5 downto 0);
  signal dma_hp_axi_awlen    : std_logic_vector (7 downto 0);
  signal dma_hp_axi_awlock   : std_logic_vector (1 downto 0);
  signal dma_hp_axi_awprot   : std_logic_vector (2 downto 0);
  signal dma_hp_axi_awqos    : std_logic_vector (3 downto 0);
  signal dma_hp_axi_awready  : std_logic;
  signal dma_hp_axi_awsize   : std_logic_vector (2 downto 0);
  signal dma_hp_axi_awvalid  : std_logic;
  signal dma_hp_axi_bid      : std_logic_vector (5 downto 0);
  signal dma_hp_axi_bready   : std_logic;
  signal dma_hp_axi_bresp    : std_logic_vector (1 downto 0);
  signal dma_hp_axi_bvalid   : std_logic;
  signal dma_hp_axi_rdata    : std_logic_vector (31 downto 0);
  signal dma_hp_axi_rlast    : std_logic;
  signal dma_hp_axi_rready   : std_logic;
  signal dma_hp_axi_rresp    : std_logic_vector (1 downto 0);
  signal dma_hp_axi_rvalid   : std_logic;
  signal dma_hp_axi_wdata    : std_logic_vector (31 downto 0);
  signal dma_hp_axi_arregion : std_logic_vector (3 downto 0) := (others => '0');
  signal dma_hp_axi_awregion : std_logic_vector (3 downto 0) := (others => '0');
  signal dma_hp_axi_wlast    : std_logic;
  signal dma_hp_axi_wready   : std_logic;
  signal dma_hp_axi_wstrb    : std_logic_vector (3 downto 0);
  signal dma_hp_axi_wvalid   : std_logic;

  signal ipb_axi_aresetn : std_logic_vector (0 to 0);
  signal ipb_axi_araddr  : std_logic_vector (31 downto 0);
  signal ipb_axi_arprot  : std_logic_vector (2 downto 0);
  signal ipb_axi_arready : std_logic;
  signal ipb_axi_arvalid : std_logic;
  signal ipb_axi_awaddr  : std_logic_vector (31 downto 0);
  signal ipb_axi_awprot  : std_logic_vector (2 downto 0);
  signal ipb_axi_awready : std_logic;
  signal ipb_axi_awvalid : std_logic;
  signal ipb_axi_bready  : std_logic;
  signal ipb_axi_bresp   : std_logic_vector (1 downto 0);
  signal ipb_axi_bvalid  : std_logic;
  signal ipb_axi_rdata   : std_logic_vector (31 downto 0);
  signal ipb_axi_rready  : std_logic;
  signal ipb_axi_rresp   : std_logic_vector (1 downto 0);
  signal ipb_axi_rvalid  : std_logic;
  signal ipb_axi_wdata   : std_logic_vector (31 downto 0);
  signal ipb_axi_wready  : std_logic;
  signal ipb_axi_wstrb   : std_logic_vector (3 downto 0);
  signal ipb_axi_wvalid  : std_logic;

  signal irq_f2p_0 : std_logic_vector (0 to 0) := (others => '0');

  -------------------------- AXI-IPbus bridge ---------------------------------

  --AXI
  signal ipb_axi_clk  : std_logic;
  signal ipb_axi_mosi : t_axi_lite_mosi;
  signal ipb_axi_miso : t_axi_lite_miso;

  signal ipb_miso_arr_int : ipb_rbus_array(IPB_SLAVES - 1 downto 0) := (others => (ipb_rdata => (others => '0'), ipb_ack => '0', ipb_err => '0'));
  signal ipb_mosi_arr_int : ipb_wbus_array(IPB_SLAVES - 1 downto 0);

  -- RAM Buffer occupancy
  signal ram_buff_a_occupancy  : std_logic_vector(31 downto 0) := (others => '0');
  signal ram_buff_b_occupancy  : std_logic_vector(31 downto 0) := (others => '0');
  signal dma_pointer           : std_logic_vector(31 downto 0);

  signal ram_a_occ_rst_ext      : std_logic;
  signal ram_b_occ_rst_ext      : std_logic;
  signal ram_toggle_request_ext : std_logic;

  signal ram_a_occ_rst          : std_logic;
  signal ram_b_occ_rst          : std_logic;
  signal ram_toggle_request     : std_logic;

  ------ Register signals begin (this section is generated by generate_registers.py -- do not edit)
    signal regs_read_arr        : t_std32_array(REG_PS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_write_arr       : t_std32_array(REG_PS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_addresses       : t_std32_array(REG_PS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_defaults        : t_std32_array(REG_PS_NUM_REGS - 1 downto 0) := (others => (others => '0'));
    signal regs_read_pulse_arr  : std_logic_vector(REG_PS_NUM_REGS - 1 downto 0) := (others => '0');
    signal regs_write_pulse_arr : std_logic_vector(REG_PS_NUM_REGS - 1 downto 0) := (others => '0');
    signal regs_read_ready_arr  : std_logic_vector(REG_PS_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_write_done_arr  : std_logic_vector(REG_PS_NUM_REGS - 1 downto 0) := (others => '1');
    signal regs_writable_arr    : std_logic_vector(REG_PS_NUM_REGS - 1 downto 0) := (others => '0');
  ------ Register signals end ----------------------------------------------

  signal ipb_clk_rate : std_logic_vector (31 downto 0) := (others => '0');

begin

  gaps_ps_interface_wrapper_inst : entity xil_defaultlib.gaps_ps_interface_wrapper
    port map (

      dma_axi_clk_o => dma_axi_aclk,

      IIC_0_0_scl_io => emio_scl,
      IIC_0_0_sda_io => emio_sda,

      ipb_clk => ipb_axi_clk,

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
      dma_hp_axi_araddr    => dma_hp_axi_araddr,
      dma_hp_axi_arburst   => dma_hp_axi_arburst,
      dma_hp_axi_arcache   => dma_hp_axi_arcache,
      --dma_hp_axi_aruser  => dma_hp_axi_aruser,
      --dma_hp_axi_awuser  => dma_hp_axi_awuser,
      dma_hp_axi_arid      => dma_hp_axi_arid,
      dma_hp_axi_arlen     => dma_hp_axi_arlen,
      dma_hp_axi_arlock(0) => dma_hp_axi_arlock(0),
      dma_hp_axi_arprot    => dma_hp_axi_arprot,
      dma_hp_axi_arqos     => dma_hp_axi_arqos,
      dma_hp_axi_arready   => dma_hp_axi_arready,
      dma_hp_axi_arsize    => dma_hp_axi_arsize,
      dma_hp_axi_arvalid   => dma_hp_axi_arvalid,
      dma_hp_axi_awaddr    => dma_hp_axi_awaddr,
      dma_hp_axi_awburst   => dma_hp_axi_awburst,
      dma_hp_axi_awcache   => dma_hp_axi_awcache,
      dma_hp_axi_awid      => dma_hp_axi_awid,
      dma_hp_axi_awlen     => dma_hp_axi_awlen,
      dma_hp_axi_awlock(0) => dma_hp_axi_awlock(0),
      dma_hp_axi_awprot    => dma_hp_axi_awprot,
      dma_hp_axi_awqos     => dma_hp_axi_awqos,
      dma_hp_axi_awready   => dma_hp_axi_awready,
      dma_hp_axi_awsize    => dma_hp_axi_awsize,
      dma_hp_axi_awvalid   => dma_hp_axi_awvalid,
      dma_hp_axi_awregion  => dma_hp_axi_awregion,
      dma_hp_axi_arregion  => dma_hp_axi_arregion,
      dma_hp_axi_bid       => dma_hp_axi_bid,
      dma_hp_axi_bready    => dma_hp_axi_bready,
      dma_hp_axi_bresp     => dma_hp_axi_bresp,
      dma_hp_axi_bvalid    => dma_hp_axi_bvalid,
      dma_hp_axi_rdata     => dma_hp_axi_rdata,
      dma_hp_axi_rlast     => dma_hp_axi_rlast,
      dma_hp_axi_rready    => dma_hp_axi_rready,
      dma_hp_axi_rresp     => dma_hp_axi_rresp,
      dma_hp_axi_rvalid    => dma_hp_axi_rvalid,
      dma_hp_axi_wdata     => dma_hp_axi_wdata,
      dma_hp_axi_wlast     => dma_hp_axi_wlast,
      dma_hp_axi_wready    => dma_hp_axi_wready,
      dma_hp_axi_wstrb     => dma_hp_axi_wstrb,
      dma_hp_axi_wvalid    => dma_hp_axi_wvalid,

      ipb_axi_aresetn    => ipb_axi_aresetn,  -- ipb_axi_aresetn : out std_logic_vector (0 to 0 );
      ipb_axi_araddr     => ipb_axi_araddr,   -- ipb_axi_araddr  : out std_logic_vector (31 downto 0 );
      ipb_axi_arprot     => ipb_axi_arprot,   -- ipb_axi_arprot  : out std_logic_vector (2 downto 0 );
      ipb_axi_arready(0) => ipb_axi_arready,  -- ipb_axi_arready : in  std_logic_vector (0 to 0 );
      ipb_axi_arvalid(0) => ipb_axi_arvalid,  -- ipb_axi_arvalid : out std_logic_vector (0 to 0 );
      ipb_axi_awaddr     => ipb_axi_awaddr,   -- ipb_axi_awaddr  : out std_logic_vector (31 downto 0 );
      ipb_axi_awprot     => ipb_axi_awprot,   -- ipb_axi_awprot  : out std_logic_vector (2 downto 0 );
      ipb_axi_awready(0) => ipb_axi_awready,  -- ipb_axi_awready : in  std_logic_vector (0 to 0 );
      ipb_axi_awvalid(0) => ipb_axi_awvalid,  -- ipb_axi_awvalid : out std_logic_vector (0 to 0 );
      ipb_axi_bready(0)  => ipb_axi_bready,   -- ipb_axi_bready  : out std_logic_vector (0 to 0 );
      ipb_axi_bresp      => ipb_axi_bresp,    -- ipb_axi_bresp   : in  std_logic_vector (1 downto 0 );
      ipb_axi_bvalid(0)  => ipb_axi_bvalid,   -- ipb_axi_bvalid  : in  std_logic_vector (0 to 0 );
      ipb_axi_rdata      => ipb_axi_rdata,    -- ipb_axi_rdata   : in  std_logic_vector (31 downto 0 );
      ipb_axi_rready(0)  => ipb_axi_rready,   -- ipb_axi_rready  : out std_logic_vector (0 to 0 );
      ipb_axi_rresp      => ipb_axi_rresp,    -- ipb_axi_rresp   : in  std_logic_vector (1 downto 0 );
      ipb_axi_rvalid(0)  => ipb_axi_rvalid,   -- ipb_axi_rvalid  : in  std_logic_vector (0 to 0 );
      ipb_axi_wdata      => ipb_axi_wdata,    -- ipb_axi_wdata   : out std_logic_vector (31 downto 0 );
      ipb_axi_wready(0)  => ipb_axi_wready,   -- ipb_axi_wready  : in  std_logic_vector (0 to 0 );
      ipb_axi_wstrb      => ipb_axi_wstrb,    -- ipb_axi_wstrb   : out std_logic_vector (3 downto 0 );
      ipb_axi_wvalid(0)  => ipb_axi_wvalid,   -- ipb_axi_wvalid  : out std_logic_vector (0 to 0 );

      irq_f2p_0 => irq_f2p_0
      );

  --------------------------------------------------------------------------------
  -- DMA Controller
  --------------------------------------------------------------------------------

  process (clk33) is
  begin
    if (rising_edge(clk33)) then
      dma_reset <= dma_reset_i;
    end if;
  end process;

  xpm_dma_reset_sync : xpm_cdc_sync_rst
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      INIT         => 1  -- 0=initialize synchronization registers to 0, 1=initialize
      )
    port map (
      dest_clk => dma_axi_aclk,
      src_rst  => dma_reset_i or dma_reset,
      dest_rst => dma_reset_synced
      );

  xpm_dma_ctrl_reset_sync : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      RST_USED     => 0  -- integer; 0=no reset, 1=implement reset
      )
    port map (
      src_rst    => '0',
      dest_rst   => '0',
      src_clk    => clk33,
      dest_clk   => dma_axi_aclk,
      src_pulse  => dma_control_reset_i,
      dest_pulse => dma_control_reset_ext
      );

  xpm_dma_clear_sync : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      RST_USED     => 0  -- integer; 0=no reset, 1=implement reset
      )
    port map (
      src_rst    => '0',
      dest_rst   => '0',
      src_clk    => clk33,
      dest_clk   => dma_axi_aclk,
      src_pulse  => dma_clear_i,
      dest_pulse => dma_clear_ext
      );

  xpm_cdc_gray_inst : xpm_cdc_gray
    generic map (
      DEST_SYNC_FF          => 2,          -- DECIMAL; range: 2-10
      INIT_SYNC_FF          => 0,          -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT            => 0,          -- DECIMAL; 0=disable registered output, 1=enable registered output
      SIM_ASSERT_CHK        => 0,          -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SIM_LOSSLESS_GRAY_CHK => 0,          -- DECIMAL; 0=disable lossless check, 1=enable lossless check
      WIDTH                 => 32          -- DECIMAL; range: 2-32
      )
    port map (
      dest_out_bin => packet_counter,      -- WIDTH-bit output: Binary input bus (src_in_bin) synchronized to destination clock domain. This output is combinatorial unless REG_OUTPUT is set to 1.
      dest_clk     => fifo_clock_in,       -- 1-bit input: Destination clock.
      src_clk      => dma_axi_aclk,        -- 1-bit input: Source clock.
      src_in_bin   => packet_counter_xdma  -- WIDTH-bit input: Binary input bus that will be synchronized to the destination clock domain.
      );
      
  --------------------------------------------------------------------------------
  -- RAM Buffer occupancy monitoring
  --------------------------------------------------------------------------------
  
    xpm_cdc_gray_inst_ram_buff_a : xpm_cdc_gray
    generic map (
      DEST_SYNC_FF          => 2,          -- DECIMAL; range: 2-10
      INIT_SYNC_FF          => 0,          -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT            => 0,          -- DECIMAL; 0=disable registered output, 1=enable registered output
      SIM_ASSERT_CHK        => 0,          -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SIM_LOSSLESS_GRAY_CHK => 0,          -- DECIMAL; 0=disable lossless check, 1=enable lossless check
      WIDTH                 => 32          -- DECIMAL; range: 2-32
      )
    port map (
      dest_out_bin => ram_buff_a_occupancy_o,  -- WIDTH-bit output: Binary input bus (src_in_bin) synchronized to destination clock domain. This output is combinatorial unless REG_OUTPUT is set to 1.
      dest_clk     => fifo_clock_in,           -- 1-bit input: Destination clock.
      src_clk      => dma_axi_aclk,            -- 1-bit input: Source clock.
      src_in_bin   => ram_buff_a_occupancy     -- WIDTH-bit input: Binary input bus that will be synchronized to the destination clock domain.
      );


    xpm_cdc_gray_inst_ram_buff_b : xpm_cdc_gray
    generic map (
      DEST_SYNC_FF          => 2,          -- DECIMAL; range: 2-10
      INIT_SYNC_FF          => 0,          -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT            => 0,          -- DECIMAL; 0=disable registered output, 1=enable registered output
      SIM_ASSERT_CHK        => 0,          -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SIM_LOSSLESS_GRAY_CHK => 0,          -- DECIMAL; 0=disable lossless check, 1=enable lossless check
      WIDTH                 => 32          -- DECIMAL; range: 2-32
      )
    port map (
      dest_out_bin => ram_buff_b_occupancy_o,      -- WIDTH-bit output: Binary input bus (src_in_bin) synchronized to destination clock domain. This output is combinatorial unless REG_OUTPUT is set to 1.
      dest_clk     => fifo_clock_in,       -- 1-bit input: Destination clock.
      src_clk      => dma_axi_aclk,        -- 1-bit input: Source clock.
      src_in_bin   => ram_buff_b_occupancy  -- WIDTH-bit input: Binary input bus that will be synchronized to the destination clock domain.
      );

    xpm_cdc_gray_inst_ram_buff_dma_ptr : xpm_cdc_gray
    generic map (
      DEST_SYNC_FF          => 2,          -- DECIMAL; range: 2-10
      INIT_SYNC_FF          => 0,          -- DECIMAL; 0=disable simulation init values, 1=enable simulation init values
      REG_OUTPUT            => 0,          -- DECIMAL; 0=disable registered output, 1=enable registered output
      SIM_ASSERT_CHK        => 0,          -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      SIM_LOSSLESS_GRAY_CHK => 0,          -- DECIMAL; 0=disable lossless check, 1=enable lossless check
      WIDTH                 => 32          -- DECIMAL; range: 2-32
      )
    port map (
      dest_out_bin => dma_pointer_o,      -- WIDTH-bit output: Binary input bus (src_in_bin) synchronized to destination clock domain. This output is combinatorial unless REG_OUTPUT is set to 1.
      dest_clk     => fifo_clock_in,       -- 1-bit input: Destination clock.
      src_clk      => dma_axi_aclk,        -- 1-bit input: Source clock.
      src_in_bin   => dma_pointer  -- WIDTH-bit input: Binary input bus that will be synchronized to the destination clock domain.
      );
      
  xpm_ram_buff_occ_a_reset : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      RST_USED     => 0  -- integer; 0=no reset, 1=implement reset
      )
    port map (
      src_clk    => clk33,
      src_pulse  => ram_a_occ_rst_i,
      src_rst    => '0',
      dest_rst   => '0',
      dest_clk   => dma_axi_aclk,
      dest_pulse => ram_a_occ_rst_ext
      );
      
  xpm_ram_buff_occ_b_reset : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      RST_USED     => 0  -- integer; 0=no reset, 1=implement reset
      )
    port map (
      src_clk    => clk33,
      src_pulse  => ram_b_occ_rst_i,
      src_rst    => '0',
      dest_rst   => '0',
      dest_clk   => dma_axi_aclk,
      dest_pulse => ram_b_occ_rst_ext
      );

  xpm_ram_toggle_req_inst : xpm_cdc_pulse
    generic map (
      DEST_SYNC_FF => 2, -- range: 2-10
      RST_USED     => 0  -- integer; 0=no reset, 1=implement reset
      )
    port map (
      src_clk    => clk33,
      src_pulse  => ram_toggle_request_i,
      src_rst    => '0',
      dest_rst   => '0',
      dest_clk   => dma_axi_aclk,
      dest_pulse => ram_toggle_request_ext
      );

  dma_controller_inst : entity dma.dma_controller
    generic map (
      WORDS_TO_SEND => 16,
      c_DEBUG       => false,
      HEAD          => x"aaaa",
      TAIL          => x"5555"
      )
    port map (

      packet_sent_o => packet_counter_xdma,
      reset_i       => dma_control_reset or dma_control_reset_ext or dma_reset_synced,
      clear_ps_mem  => dma_clear_ext or dma_clear,

      clk_in      => fifo_clock_in,
      clk_axi     => dma_axi_aclk,
      fifo_in     => fifo_data_in,
      fifo_wr_en  => fifo_data_wen,
      fifo_full   => open,              -- TODO: connect to monitor
      daq_busy_in => daq_busy_in,
      
      -- RAM occupancy monitoring
      ram_a_occ_rst          => ram_a_occ_rst or ram_a_occ_rst_ext,
      ram_b_occ_rst          => ram_b_occ_rst or ram_b_occ_rst_ext,
      ram_toggle_request_i   => ram_toggle_request or ram_toggle_request_ext,
      ram_buff_a_occupancy_o => ram_buff_a_occupancy,
      ram_buff_b_occupancy_o => ram_buff_b_occupancy,
      dma_pointer_o          => dma_pointer,
      
      m_axi_s2mm_awid    => dma_hp_axi_awid (3 downto 0),
      m_axi_s2mm_awaddr  => dma_hp_axi_awaddr,
      m_axi_s2mm_awlen   => dma_hp_axi_awlen (7 downto 0),
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
      m_axi_mm2s_arid    => dma_hp_axi_arid (3 downto 0),
      m_axi_mm2s_araddr  => dma_hp_axi_araddr,
      m_axi_mm2s_arlen   => dma_hp_axi_arlen (7 downto 0),
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
  --
  --    (with clock domain crossings)
  ------------------------------------------------------------------------------------------------------------------------

  ipb_cdc : for I in 0 to 0 generate

    constant addrb   : natural := ipb_mosi_arr_int(I).ipb_addr'length;
    constant wdatb   : natural := ipb_mosi_arr_int(I).ipb_wdata'length;
    constant rdatb   : natural := ipb_miso_arr_int(I).ipb_rdata'length;
    constant strobeb : natural := 1;
    constant writeb  : natural := 1;
    constant ackb    : natural := 1;
    constant errb    : natural := 1;

    constant MOSIB : natural := addrb + wdatb + strobeb + writeb;
    constant MISOB : natural := rdatb + ackb + errb;

    signal mosi_pre_cdc  : std_logic_vector (MOSIB-1 downto 0) := (others => '0');
    signal mosi_post_cdc : std_logic_vector (MOSIB-1 downto 0) := (others => '0');

    signal miso_pre_cdc  : std_logic_vector (MISOB-1 downto 0) := (others => '0');
    signal miso_post_cdc : std_logic_vector (MISOB-1 downto 0) := (others => '0');

  begin

    --------------------------------------------------------------------------------
    -- From master, to slaves
    --------------------------------------------------------------------------------

    -- internal signal to slv
    mosi_pre_cdc <= ipb_mosi_arr_int(I).ipb_addr & ipb_mosi_arr_int(I).ipb_wdata &
                    ipb_mosi_arr_int(I).ipb_strobe & ipb_mosi_arr_int(I).ipb_write;

    -- outputs
    ipb_mosi_arr(I).ipb_addr   <= mosi_post_cdc (2+wdatb+addrb-1 downto 2+wdatb);
    ipb_mosi_arr(I).ipb_wdata  <= mosi_post_cdc (2+wdatb-1 downto 2);
    ipb_mosi_arr(I).ipb_strobe <= mosi_post_cdc (1);
    ipb_mosi_arr(I).ipb_write  <= mosi_post_cdc (0);

    mosi_sync : entity work.fifo_async
      generic map (
        DEPTH    => 16,
        WR_WIDTH => MOSIB,
        RD_WIDTH => MOSIB)
      port map (
        rst    => (not pl_mmcm_locked) or (not ipb_axi_aresetn(0)),
        wr_clk => ipb_axi_clk,
        rd_clk => ipb_clk,
        wr_en  => '1',
        rd_en  => '1',
        din    => mosi_pre_cdc,
        dout   => mosi_post_cdc,
        valid  => open,
        full   => open,
        empty  => open
        );

    --------------------------------------------------------------------------------
    -- From slaves, to master
    --------------------------------------------------------------------------------

    -- input from slaves, to slv
    miso_pre_cdc <= ipb_miso_arr(I).ipb_rdata & ipb_miso_arr(I).ipb_ack &
                    ipb_miso_arr(I).ipb_err;

    -- from cdc, to bridge
    ipb_miso_arr_int(I).ipb_rdata <= miso_post_cdc (2+rdatb-1 downto 2);
    ipb_miso_arr_int(I).ipb_ack   <= miso_post_cdc (1);
    ipb_miso_arr_int(I).ipb_err   <= miso_post_cdc (0);

    miso_sync : entity work.fifo_async
      generic map (
        DEPTH    => 16,
        WR_WIDTH => MISOB,
        RD_WIDTH => MISOB)
      port map (
        rst    => (not pl_mmcm_locked) or (not ipb_axi_aresetn_sync),
        wr_clk => ipb_clk,
        rd_clk => ipb_axi_clk,
        wr_en  => '1',
        rd_en  => '1',
        din    => miso_pre_cdc,
        dout   => miso_post_cdc,
        valid  => open,
        full   => open,
        empty  => open
        );

  end generate;

  ipb_clk <= clk33;

  xpm_cdc_sync_rst_inst : xpm_cdc_sync_rst
    generic map (
      DEST_SYNC_FF => 2,                -- range: 2-10
      INIT         => 1                 -- 0=initialize synchronization registers to 0, 1=initialize
      )
    port map (
      dest_rst => ipb_reset,
      dest_clk => ipb_clk,
      src_rst  => ipb_reset_async
      );

  xpm_cdc_sync_axi_rst_inst : xpm_cdc_sync_rst
    generic map (
      DEST_SYNC_FF => 2,                -- range: 2-10
      INIT         => 1                 -- 0=initialize synchronization registers to 0, 1=initialize
      )
    port map (
      dest_rst => ipb_axi_aresetn_sync,
      dest_clk => ipb_clk,
      src_rst  => ipb_axi_aresetn(0)
      );

  i_axi_ipbus_bridge : entity work.axi_ipbus_bridge
    generic map(
      C_NUM_IPB_SLAVES   => IPB_SLAVES,
      C_S_AXI_DATA_WIDTH => C_IPB_AXI_DATA_WIDTH,
      C_S_AXI_ADDR_WIDTH => C_IPB_AXI_ADDR_WIDTH
      )
    port map(
      ipb_reset_o   => ipb_reset_async,
      ipb_clk_o     => open,
      ipb_miso_i    => ipb_miso_arr_int,
      ipb_mosi_o    => ipb_mosi_arr_int,
      S_AXI_ACLK    => ipb_axi_clk,
      S_AXI_ARESETN => ipb_axi_aresetn(0),
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

  --------------------------------------------------------------------------------
  -- Frequency Monitors
  --------------------------------------------------------------------------------

  frequency_counter_ipb_clk : entity work.frequency_counter
    generic map (
      clk_a_freq => 1000000
      )
    port map (
      reset => not ipb_axi_aresetn(0),
      clk_a => ipb_axi_clk,
      clk_b => ipb_clk,
      rate  => ipb_clk_rate
      );

  --===============================================================================================
  -- (this section is generated by tools/generate_registers.py -- do not edit)
  --==== Registers begin ==========================================================================

    -- IPbus slave instanciation
    ipbus_slave_inst : entity work.ipbus_slave_tmr
        generic map(
           g_ENABLE_TMR           => EN_TMR_IPB_SLAVE_PS,
           g_NUM_REGS             => REG_PS_NUM_REGS,
           g_ADDR_HIGH_BIT        => REG_PS_ADDRESS_MSB,
           g_ADDR_LOW_BIT         => REG_PS_ADDRESS_LSB,
           g_USE_INDIVIDUAL_ADDRS => true
       )
       port map(
           ipb_reset_i            => not ipb_axi_aresetn(0),
           ipb_clk_i              => ipb_axi_clk,
           ipb_mosi_i             => ipb_mosi_arr_int(1),
           ipb_miso_o             => ipb_miso_arr_int(1),
           usr_clk_i              => ipb_axi_clk,
           regs_read_arr_i        => regs_read_arr,
           regs_write_arr_o       => regs_write_arr,
           read_pulse_arr_o       => regs_read_pulse_arr,
           write_pulse_arr_o      => regs_write_pulse_arr,
           regs_read_ready_arr_i  => regs_read_ready_arr,
           regs_write_done_arr_i  => regs_write_done_arr,
           individual_addrs_arr_i => regs_addresses,
           regs_defaults_arr_i    => regs_defaults,
           writable_regs_i        => regs_writable_arr
      );

    -- Addresses
    regs_addresses(0)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "00" & x"00";
    regs_addresses(1)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "00" & x"01";
    regs_addresses(2)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "00" & x"10";
    regs_addresses(3)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"00";
    regs_addresses(4)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"01";
    regs_addresses(5)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"02";
    regs_addresses(6)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"03";
    regs_addresses(7)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"04";
    regs_addresses(8)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"05";
    regs_addresses(9)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"06";
    regs_addresses(10)(REG_PS_ADDRESS_MSB downto REG_PS_ADDRESS_LSB) <= "01" & x"07";

    -- Connect read signals
    regs_read_arr(0)(REG_PS_PL_MMCM_LOCKED_BIT) <= pl_mmcm_locked;
    regs_read_arr(1)(REG_PS_IPB_CLK_RATE_MSB downto REG_PS_IPB_CLK_RATE_LSB) <= ipb_clk_rate;
    regs_read_arr(2)(REG_PS_CNT_DMA_READOUTS_COMPLETED_MSB downto REG_PS_CNT_DMA_READOUTS_COMPLETED_LSB) <= packet_counter_xdma;
    regs_read_arr(5)(REG_PS_DMA_RAM_A_OCCUPANCY_MSB downto REG_PS_DMA_RAM_A_OCCUPANCY_LSB) <= ram_buff_a_occupancy;
    regs_read_arr(6)(REG_PS_DMA_RAM_B_OCCUPANCY_MSB downto REG_PS_DMA_RAM_B_OCCUPANCY_LSB) <= ram_buff_b_occupancy;
    regs_read_arr(7)(REG_PS_DMA_DMA_POINTER_MSB downto REG_PS_DMA_DMA_POINTER_LSB) <= dma_pointer;

    -- Connect write signals

    -- Connect write pulse signals
    ram_a_occ_rst <= regs_write_pulse_arr(3);
    ram_b_occ_rst <= regs_write_pulse_arr(4);
    ram_toggle_request <= regs_write_pulse_arr(8);
    dma_clear <= regs_write_pulse_arr(9);
    dma_control_reset <= regs_write_pulse_arr(10);

    -- Connect write done signals

    -- Connect read pulse signals

    -- Connect counter instances

    -- Connect rate instances

    -- Connect read ready signals

    -- Defaults

    -- Define writable regs

  -- --==== Registers end ============================================================================

end Behavioral;
