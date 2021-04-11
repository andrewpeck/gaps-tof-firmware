------------------------------------------------------------
-- DMA Controller 
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity dma_controller is
  generic (
    C_DEBUG       : boolean                        := false;
    words_to_send : integer                        := 16;
    ram_buff_size : integer                        := 67108864;
    MAX_ADDRESS   : std_logic_vector(31 downto 0)  := x"1F900000";
    START_ADDRESS : std_logic_vector(31 downto 0)  := x"1B900000";
    HEAD          : std_logic_vector (15 downto 0) := x"AAAA";
    TAIL          : std_logic_vector (15 downto 0) := x"5555"
    );
  port (
    CLK_IN     : in  std_logic;
    CLK_AXI    : in  std_logic;
    RST_IN     : in  std_logic;
    fifo_in    : in  std_logic_vector(31 downto 0);
    fifo_wr_en : in  std_logic;
    fifo_full  : out std_logic;

    ----
    -- Datamover AXI4MM Signals
    ---

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

    ----
    -- DMA AXI4 Lite Registers
    ---
    packet_sent : out std_logic_vector(31 downto 0) := (others => '0');
    reset_sys   : in  std_logic                     := '0'
    );
end dma_controller;

architecture Behavioral of dma_controller is

  component axis2aximm is
    port (
      s2mm_halt       : in  std_logic;
      s2mm_halt_cmplt : out std_logic;
      s2mm_dbg_sel    : in  std_logic_vector(3 downto 0);

      m_axi_s2mm_aclk            : in  std_logic;
      m_axi_s2mm_aresetn         : in  std_logic;
      s2mm_err                   : out std_logic;
      m_axis_s2mm_cmdsts_awclk   : in  std_logic;
      m_axis_s2mm_cmdsts_aresetn : in  std_logic;

      --s2mm Command
      s_axis_s2mm_cmd_tvalid : in  std_logic;
      s_axis_s2mm_cmd_tready : out std_logic;
      s_axis_s2mm_cmd_tdata  : in  std_logic_vector(71 downto 0);
      --s2mm Status
      m_axis_s2mm_sts_tvalid : out std_logic;
      m_axis_s2mm_sts_tready : in  std_logic;
      m_axis_s2mm_sts_tdata  : out std_logic_vector(7 downto 0);
      m_axis_s2mm_sts_tkeep  : out std_logic_vector(0 downto 0);
      m_axis_s2mm_sts_tlast  : out std_logic;
      m_axi_s2mm_awid        : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awaddr      : out std_logic_vector(31 downto 0);
      m_axi_s2mm_awlen       : out std_logic_vector(7 downto 0);
      m_axi_s2mm_awsize      : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awburst     : out std_logic_vector(1 downto 0);
      m_axi_s2mm_awprot      : out std_logic_vector(2 downto 0);
      m_axi_s2mm_awcache     : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awuser      : out std_logic_vector(3 downto 0);
      m_axi_s2mm_awvalid     : out std_logic;
      m_axi_s2mm_awready     : in  std_logic;
      m_axi_s2mm_wdata       : out std_logic_vector(31 downto 0);
      m_axi_s2mm_wstrb       : out std_logic_vector(3 downto 0);
      m_axi_s2mm_wlast       : out std_logic;
      m_axi_s2mm_wvalid      : out std_logic;
      m_axi_s2mm_wready      : in  std_logic;
      m_axi_s2mm_bresp       : in  std_logic_vector(1 downto 0);
      m_axi_s2mm_bvalid      : in  std_logic;
      m_axi_s2mm_bready      : out std_logic;
      --s2mm stream data
      s_axis_s2mm_tdata      : in  std_logic_vector(31 downto 0);
      s_axis_s2mm_tkeep      : in  std_logic_vector(3 downto 0);
      s_axis_s2mm_tlast      : in  std_logic;
      s_axis_s2mm_tvalid     : in  std_logic;
      s_axis_s2mm_tready     : out std_logic;
      --------------------------------------
      s2mm_allow_addr_req    : in  std_logic;
      s2mm_addr_req_posted   : out std_logic;
      s2mm_wr_xfer_cmplt     : out std_logic;
      s2mm_ld_nxt_len        : out std_logic;
      s2mm_wr_len            : out std_logic_vector(7 downto 0)
      );
  end component;

  component fifo_generator_0 is
    port (
      rst           : in  std_logic;
      wr_clk        : in  std_logic;
      rd_clk        : in  std_logic;
      din           : in  std_logic_vector(31 downto 0);
      wr_en         : in  std_logic;
      rd_en         : in  std_logic;
      dout          : out std_logic_vector(31 downto 0);
      full          : out std_logic;
      empty         : out std_logic;
      valid         : out std_logic;
      rd_data_count : out std_logic_vector(9 downto 0);
      prog_full     : out std_logic;
      prog_empty    : out std_logic;
      wr_rst_busy   : out std_logic;
      rd_rst_busy   : out std_logic
      );
  end component;

  component ila_s2mm is
    port (
      clk     : in std_logic;
      probe0  : in std_logic;
      probe1  : in std_logic;
      probe2  : in std_logic_vector(71 downto 0);
      probe3  : in std_logic_vector(31 downto 0);
      probe4  : in std_logic_vector(3 downto 0);
      probe5  : in std_logic;
      probe6  : in std_logic;
      probe7  : in std_logic;
      probe8  : in std_logic_vector(31 downto 0);
      probe9  : in std_logic;
      probe10 : in std_logic_vector(31 downto 0);
      probe11 : in std_logic;
      probe12 : in std_logic;
      probe13 : in std_logic;
      probe14 : in std_logic;
      probe15 : in std_logic_vector(7 downto 0);
      probe16 : in std_logic;
      probe17 : in std_logic;
      probe18 : in std_logic_vector(7 downto 0);
      probe19 : in std_logic;
      probe20 : in std_logic
      );
  end component;

  type cmd_state is (IDLE, SET, DONE);
  type data_state is (IDLE, ASSERT_CMD, DELAY0, READ_FIFO, DONE, DELAY1);

  signal aresetn      : std_logic := '1';
  signal RESET_ACTIVE : std_logic := '0';

  signal s2mm_cmd_state  : cmd_state;
  signal s2mm_data_state : data_state;

  signal data_counter : std_logic_vector(9 downto 0);

  --fifo signals
  signal fifo_out         : std_logic_vector(31 downto 0);
  signal fifo_count       : std_logic_vector(9 downto 0);
  signal fifo_rd_en       : std_logic;
  signal fifo_out_valid   : std_logic;
  signal wfifo_full       : std_logic;
  signal wfifo_empty      : std_logic;
  signal wfifo_prog_full  : std_logic;
  signal wfifo_prog_empty : std_logic;
  signal wr_rst_busy      : std_logic;
  signal rd_rst_busy      : std_logic;

  --datamover signals
  --command port
  signal s2mm_cmd_tvalid : std_logic;
  signal s2mm_cmd_tready : std_logic;
  signal s2mm_cmd_tdata  : std_logic_vector(71 downto 0);

  --data port
  signal s2mm_tdata    : std_logic_vector(31 downto 0);
  signal s2mm_tkeep    : std_logic_vector(3 downto 0);
  signal s2mm_tlast    : std_logic;
  signal s2mm_tlast_r1 : std_logic;
  signal s2mm_tlast_r2 : std_logic;
  signal s2mm_tvalid   : std_logic;
  signal s2mm_tready   : std_logic;

  signal btt       : std_logic_vector(22 downto 0);
  signal saddr     : std_logic_vector(31 downto 0);
  signal data_type : std_logic;

  signal init_cmd : std_logic;

  ---
  signal delay_counter   : integer range 0 to 21 := 0;
  signal initial_counter : integer;

  signal valid_fifo_data : std_logic_vector(31 downto 0) := (others => '0');

  signal s2mm_allow_addr_req_reg  : std_logic;
  signal s2mm_addr_req_posted_reg : std_logic;
  signal s2mm_wr_xfer_cmplt_reg   : std_logic;
  signal s2mm_ld_nxt_len_reg      : std_logic;
  signal s2mm_wr_len_reg          : std_logic_vector(7 downto 0) := (others => '0');

  --datamover status signals
  signal m_axis_s2mm_sts_tvalid_reg : std_logic;
  signal m_axis_s2mm_sts_tdata_reg  : std_logic_vector(7 downto 0);
  signal m_axis_s2mm_sts_tkeep_reg  : std_logic_vector(0 downto 0);
  signal m_axis_s2mm_sts_tlast_Reg  : std_logic;
  signal s2mm_err_reg               : std_logic := '0';

  signal reset_pointer_address : std_logic := '0';
  
  --Circular buffer wrap signals
  signal mem_bytes_written : unsigned(31 downto 0) := (others => '0');
  signal mem_buff_size     : unsigned(31 downto 0) := to_unsigned(ram_buff_size, 32);

begin

  --active low reset for logic
  aresetn <= not (rst_in or reset_sys);

  --------------------------------------------------------------------------------------------
  -- Datamover Commmand Interface Signals
  --------------------------------------------------------------------------------------------
  -- incr = 1, fixed = 0
  data_type <= '1';

  --bytes to transfer
  btt <= std_logic_vector(to_signed(words_to_send *4, 23));

  --s2mm command signals
  s2mm_cmd_tdata(71 downto 68) <= (others => '0');
  s2mm_cmd_tdata(67 downto 64) <= (others => '0');
  s2mm_cmd_tdata(63 downto 32) <= saddr;      --start address
  s2mm_cmd_tdata(31 downto 24) <= (others => '0');
  s2mm_cmd_tdata(23)           <= data_type;  --data type
  s2mm_cmd_tdata(22 downto 0)  <= btt;        -- bytes to transfer

  --s2mm command valid assertion
  s2mm_cmd_tvalid <= '1' when (s2mm_data_state = ASSERT_CMD) else '0';

  s2mm_tvalid <= fifo_out_valid;
  s2mm_tkeep  <= x"F";

  --------------------------------------------------------------------------------------------
  -- FIFO Generator
  --------------------------------------------------------------------------------------------
  u0 : fifo_generator_0
    port map(
      rst           => not aresetn,
      wr_clk        => CLK_IN,
      rd_clk        => CLK_AXI,
      din           => fifo_in,
      wr_en         => fifo_wr_en,
      rd_en         => fifo_rd_en,
      rd_data_count => fifo_count,
      dout          => fifo_out,
      valid         => fifo_out_valid,
      full          => wfifo_full,
      empty         => wfifo_empty,
      prog_full     => wfifo_prog_full,
      prog_empty    => wfifo_prog_empty,
      wr_rst_busy   => wr_rst_busy,
      rd_rst_busy   => rd_rst_busy
      );

  debug : if (C_DEBUG) generate
    ila_s2mm_inst : ila_s2mm
      port map(
        clk     => CLK_AXI,
        probe0  => s2mm_cmd_tvalid,
        probe1  => s2mm_cmd_tready,
        probe2  => s2mm_cmd_tdata,
        probe3  => s2mm_tdata,
        probe4  => s2mm_tkeep,
        probe5  => s2mm_tlast,
        probe6  => s2mm_tvalid,
        probe7  => s2mm_tready,
        probe8  => valid_fifo_data,
        probe9  => fifo_rd_en,
        probe10 => fifo_out,
        probe11 => s2mm_allow_addr_req_reg,
        probe12 => s2mm_addr_req_posted_reg,
        probe13 => s2mm_wr_xfer_cmplt_reg,
        probe14 => s2mm_ld_nxt_len_reg,
        probe15 => s2mm_wr_len_reg,
        probe16 => s2mm_err_reg,
        probe17 => m_axis_s2mm_sts_tvalid_reg,
        probe18 => m_axis_s2mm_sts_tdata_reg,
        probe19 => m_axis_s2mm_sts_tkeep_reg(0),
        probe20 => m_axis_s2mm_sts_tlast_Reg
        );
  end generate;

  --------------------------------------------------------------------------------------------
  -- AXI Control Signals
  --------------------------------------------------------------------------------------------

  --Keep track of packet transfers
  packet_tracker : process(CLK_AXI)
  begin
    if(rising_edge(CLK_AXI)) then
      if aresetn = RESET_ACTIVE or reset_sys = '1' then
        packet_sent <= (others => '0');
      elsif (fifo_out(15 downto 0) = TAIL)then
        packet_sent <= std_logic_vector(unsigned(packet_sent) + 1);
      else
        packet_sent <= packet_sent;
      end if;
    end if;
  end process;

  -- Restart address when x address is reached.
  address_pointer : process(CLK_AXI)
  begin
    if(rising_edge(CLK_AXI)) then
      if aresetn = '0' then
        reset_pointer_address <= '0';
      elsif (fifo_out(15 downto 0) = TAIL and mem_bytes_written > mem_buff_size) then
        reset_pointer_address <= '1';
      else
        reset_pointer_address <= '0';
      end if;
    end if;
  end process;

  address_handler : process(CLK_AXI)
  begin
    if(rising_edge(CLK_AXI)) then
      if aresetn = '0' or reset_pointer_address = '1' then
        -- TODO
        -- Make saddr a generic defined at the top for easier access
        saddr <= x"1B900000";
        mem_bytes_written <= (others => '0');
      elsif (s2mm_addr_req_posted_reg = '1') then
        saddr <= std_logic_vector(unsigned(saddr) + unsigned(btt));
        mem_bytes_written <= mem_bytes_written + unsigned(btt);
      else
        saddr <= saddr;
        mem_bytes_written <= mem_bytes_written;
      end if;
    end if;
  end process;

  s2mm_data_interface : process(CLK_AXI)
  begin
    if(rising_edge(CLK_AXI)) then
      if aresetn = '0' then
        s2mm_allow_addr_req_reg <= '0';
        s2mm_data_state         <= IDLE;
        delay_counter           <= 0;
        fifo_rd_en              <= '0';
        s2mm_tlast              <= '0';
        s2mm_tdata              <= (others => '0');
      else
        case s2mm_data_state is
          when IDLE =>
            s2mm_allow_addr_req_reg <= '1';
            if((unsigned(fifo_count) mod words_to_send) = 0 and unsigned(fifo_count) /= 0 and s2mm_cmd_tready = '1') then
              s2mm_data_state <= ASSERT_CMD;
            else
              fifo_rd_en <= '0';
            end if;

          when ASSERT_CMD =>
            s2mm_data_state <= DELAY0;

          when DELAY0 =>
            if delay_counter > 20 then
              s2mm_allow_addr_req_reg <= '0';
              s2mm_data_state         <= READ_FIFO;
              delay_counter           <= 0;
            else
              delay_counter <= delay_counter + 1;
            end if;

          when READ_FIFO =>

            if(unsigned(valid_fifo_data) >= words_to_send) then
              s2mm_tdata      <= fifo_out;
              valid_fifo_data <= (others => '0');
              s2mm_tlast      <= '1';
              fifo_rd_en      <= '0';
              s2mm_data_state <= DONE;
            else
              valid_fifo_data <= std_logic_vector(unsigned(valid_fifo_data) + 1);
              s2mm_tdata      <= fifo_out;
              fifo_rd_en      <= '1';
            end if;

          when DONE =>
            s2mm_tlast      <= '0';
            s2mm_data_state <= IDLE;
          when others => s2mm_data_state <= IDLE;
        end case;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------------------
  -- Data Mover IP
  --------------------------------------------------------------------------------------------
  u1 : axis2aximm
    port map (
      m_axi_s2mm_aclk    => CLK_AXI,
      m_axi_s2mm_aresetn => aresetn,
      s2mm_halt          => '0',
      s2mm_dbg_sel       => x"0",

      --s2mm command
      s_axis_s2mm_cmd_tvalid => s2mm_cmd_tvalid,
      s_axis_s2mm_cmd_tready => s2mm_cmd_tready,
      s_axis_s2mm_cmd_tdata  => s2mm_cmd_tdata,
      --s2mm data
      s_axis_s2mm_tdata      => s2mm_tdata,
      s_axis_s2mm_tkeep      => s2mm_tkeep,
      s_axis_s2mm_tlast      => s2mm_tlast,
      s_axis_s2mm_tvalid     => s2mm_tvalid,
      s_axis_s2mm_tready     => s2mm_tready,

      m_axis_s2mm_cmdsts_awclk   => CLK_AXI,
      m_axis_s2mm_cmdsts_aresetn => aresetn,

      m_axis_s2mm_sts_tvalid => m_axis_s2mm_sts_tvalid_reg,
      m_axis_s2mm_sts_tready => '1',
      m_axis_s2mm_sts_tdata  => m_axis_s2mm_sts_tdata_reg,
      m_axis_s2mm_sts_tkeep  => m_axis_s2mm_sts_tkeep_reg,
      m_axis_s2mm_sts_tlast  => m_axis_s2mm_sts_tlast_reg,

      m_axi_s2mm_awid      => m_axi_s2mm_awid,
      m_axi_s2mm_awaddr    => m_axi_s2mm_awaddr,
      m_axi_s2mm_awvalid   => m_axi_s2mm_awvalid,
      m_axi_s2mm_awlen     => m_axi_s2mm_awlen,
      m_axi_s2mm_awsize    => m_axi_s2mm_awsize,
      m_axi_s2mm_awburst   => m_axi_s2mm_awburst,
      m_axi_s2mm_awprot    => m_axi_s2mm_awprot,
      m_axi_s2mm_awcache   => m_axi_s2mm_awcache,
      m_axi_s2mm_awuser    => m_axi_s2mm_awuser,
      m_axi_s2mm_wdata     => m_axi_s2mm_wdata,
      m_axi_s2mm_wstrb     => m_axi_s2mm_wstrb,
      m_axi_s2mm_wlast     => m_axi_s2mm_wlast,
      m_axi_s2mm_wvalid    => m_axi_s2mm_wvalid,
      m_axi_s2mm_bresp     => m_axi_s2mm_bresp,
      m_axi_s2mm_bvalid    => m_axi_s2mm_bvalid,
      m_axi_s2mm_bready    => m_axi_s2mm_bready,
      m_axi_s2mm_awready   => m_axi_s2mm_awready,
      m_axi_s2mm_wready    => m_axi_s2mm_wready,
      s2mm_allow_addr_req  => s2mm_allow_addr_req_reg,
      s2mm_addr_req_posted => s2mm_addr_req_posted_reg,
      s2mm_wr_xfer_cmplt   => s2mm_wr_xfer_cmplt_reg,
      s2mm_ld_nxt_len      => s2mm_ld_nxt_len_reg,
      s2mm_wr_len          => s2mm_wr_len_reg,
      s2mm_err             => s2mm_err_reg

      );
end Behavioral;
