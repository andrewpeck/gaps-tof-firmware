----------------------------------------------------------------------------------
-- DMA Controller
-- GAPS DRS4 Readout Firmware
-- I. Garcia, A. Peck, S. Quinn
----------------------------------------------------------------------------------
--
-- https://www.xilinx.com/support/documentation/ip_documentation/axi_datamover/v5_1/pg022_axi_datamover.pdf
--
----------------------------------------------------------------------------------

------------------------------------------------------------
-- DMA Controller 
------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dma_controller is
  generic (
    C_DEBUG : boolean := true;

    FIFO_LATENCY : natural := 1;

    WORDS_TO_SEND : integer := 16;

    BUFF_FRAC_DIVISOR : integer := 1040384;  --Corresponds to 1/64 of RAM_BUFF_SIZE

    -- NOTE: WORDS_TO_SEND MUST NOT EXCEED MaxBurst in DataMover core (u1: axis2aximm)!

    -- TODO: make START_ADDRESS, TOP_HALF_ADDRESS programmable from userspace
    RAM_BUFF_SIZE    : integer                       := 66584576;
    START_ADDRESS    : std_logic_vector(31 downto 0) := x"04100000";
    TOP_HALF_ADDRESS : std_logic_vector(31 downto 0) := x"08100000";

    -- reserve the tail of the buffer to be allocated for overflow only,
    -- i.e., if the buffer is 64 Mb, we want to trigger a switch to the
    -- adjacent buffer at 64 Mb - max_packet_size so that the rest
    -- of the data packet has a place to be written
    --
    -- If this mechanism didn't exist, then when we trigger the buffer
    -- switch at 64 Mb, if the packet end doesn't exactly align to the buffer
    -- end then the packet would get split across two different buffers

    MAX_PACKET_SIZE : integer := 64000;  --

    HEAD : std_logic_vector(15 downto 0) := x"AAAA";
    TAIL : std_logic_vector(15 downto 0) := x"5555"
    );
  port (

    clk_in  : in std_logic;             -- daq clock
    clk_axi : in std_logic;             -- axi clock
    reset   : in std_logic;             -- active high reset, synchronous to the axi clock

    --------------------------------------------------------------
    -- RAM Occupancy signals
    --------------------------------------------------------------

    ram_a_occ_rst : in std_logic;
    ram_b_occ_rst : in std_logic;

    ram_buff_a_occupancy_o : out std_logic_vector(31 downto 0) := (others => '0');
    ram_buff_b_occupancy_o : out std_logic_vector(31 downto 0) := (others => '0');
    dma_pointer_o          : out std_logic_vector(31 downto 0) := (others => '0');


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

    m_axi_mm2s_arid    : out std_logic_vector(3 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_araddr  : out std_logic_vector(31 downto 0) := (others => '0');  -- these aren't driven
    m_axi_mm2s_arlen   : out std_logic_vector(7 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_arsize  : out std_logic_vector(2 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_arburst : out std_logic_vector(1 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_arprot  : out std_logic_vector(2 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_arcache : out std_logic_vector(3 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_aruser  : out std_logic_vector(3 downto 0)  := (others => '0');  -- these aren't driven
    m_axi_mm2s_arvalid : out std_logic                     := '0';
    m_axi_mm2s_arready : in  std_logic;
    m_axi_mm2s_rdata   : in  std_logic_vector(31 downto 0);
    m_axi_mm2s_rresp   : in  std_logic_vector(1 downto 0);
    m_axi_mm2s_rlast   : in  std_logic;
    m_axi_mm2s_rvalid  : in  std_logic;
    m_axi_mm2s_rready  : out std_logic                     := '0';

    -----------------------------------------------------------------------------
    -- DMA AXI4 Lite Registers
    -----------------------------------------------------------------------------

    packet_sent_o : out std_logic_vector(31 downto 0) := (others => '0');
    clear_ps_mem  : in  std_logic                     := '0'

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
      din           : in  std_logic_vector(16 downto 0);
      wr_en         : in  std_logic;
      rd_en         : in  std_logic;
      dout          : out std_logic_vector(33 downto 0);
      full          : out std_logic;
      empty         : out std_logic;
      valid         : out std_logic;
      rd_data_count : out std_logic_vector(8 downto 0);
      prog_full     : out std_logic;
      prog_empty    : out std_logic;
      wr_rst_busy   : out std_logic;
      rd_rst_busy   : out std_logic
      );
  end component;

  type cmd_state is (IDLE, SET, DONE);
  type data_state is (IDLE, ASSERT_CMD, DELAY0, READ_FIFO, DONE, DELAY1, CLEAR_MEM, CONTINUE_CLEAR);

  signal s2mm_cmd_state  : cmd_state;
  signal s2mm_data_state : data_state;

  signal packet_sent    : std_logic_vector(31 downto 0) := (others => '0');
  signal packet_is_tail : std_logic                     := '0';

  --------------------------------------------------------------------------------
  --data fifo signals
  --------------------------------------------------------------------------------

  signal fifo_out                 : std_logic_vector(33 downto 0);
  signal fifo_count               : std_logic_vector(8 downto 0);
  signal fifo_rd_en               : std_logic;
  signal fifo_out_valid           : std_logic;
  signal fifo_out_valid_r         : std_logic;
  signal wfifo_empty              : std_logic;
  signal wfifo_prog_full          : std_logic;
  signal wfifo_prog_empty         : std_logic;
  signal wr_rst_busy              : std_logic;
  signal rd_rst_busy              : std_logic;
  signal daq_busy_xfifo           : std_logic := '0';
  signal data_xfifo, data_xfifo_r : std_logic_vector(31 downto 0);

  --------------------------------------------------------------------------------
  --datamover signals
  --------------------------------------------------------------------------------

  --command port
  signal s2mm_cmd_tvalid : std_logic                     := '0';
  signal s2mm_cmd_tready : std_logic                     := '0';
  signal s2mm_cmd_tdata  : std_logic_vector(71 downto 0) := (others => '0');

  -- axi stream data port
  signal s2mm_tdata  : std_logic_vector(31 downto 0) := (others => '0');
  signal s2mm_tlast  : std_logic                     := '0';
  signal s2mm_tvalid : std_logic                     := '0';
  signal s2mm_tready : std_logic                     := '0';

  --bytes to transfer
  constant BTT        : std_logic_vector(22 downto 0) := std_logic_vector(to_unsigned(WORDS_TO_SEND * 4, 23));
  constant DATA_TYPE  : std_logic                     := '1';  -- incr = 1, fixed = 0
  constant S2MM_TKEEP : std_logic_vector(3 downto 0)  := x"F"; -- keep all 4 bytes in the word

  signal saddr : std_logic_vector(31 downto 0) := (others => '0');

  signal delay_counter : integer range 0 to 21 := 0;

  signal words_sent_cnt : integer range 0 to WORDS_TO_SEND;

  -- Used to control the MM2S in posting an address on the AXI4 Read address
  -- channel. A 1 allows posting and a 0 inhibits posting.
  signal s2mm_allow_addr_req_reg  : std_logic                    := '0';

  -- This output signal is asserted to 1 for one m_axi_mm2s_aclk period for each
  -- new address posted to the AXI4 Read Address Channel.
  signal s2mm_addr_req_posted_reg : std_logic                    := '0';

  signal s2mm_wr_xfer_cmplt_reg   : std_logic                    := '0';
  signal s2mm_ld_nxt_len_reg      : std_logic                    := '0';
  signal s2mm_wr_len_reg          : std_logic_vector(7 downto 0) := (others => '0');

  --datamover status signals
  signal m_axis_s2mm_sts_tvalid_reg : std_logic                    := '0';
  signal m_axis_s2mm_sts_tdata_reg  : std_logic_vector(7 downto 0) := (others => '0');
  signal m_axis_s2mm_sts_tkeep_reg  : std_logic_vector(0 downto 0) := (others => '0');
  signal m_axis_s2mm_sts_tlast_Reg  : std_logic                    := '0';
  signal s2mm_err_reg               : std_logic                    := '0';

  signal buff_switch_request  : std_logic := '0';
  signal buff_switch_response : std_logic := '0';

  --------------------------------------------------------------------------------
  --Circular buffer wrap signals
  --------------------------------------------------------------------------------

  constant CNT_ADRB : integer := integer(ceil(log2(real(RAM_BUFF_SIZE))));
  constant PTR_ADRB : integer := integer(ceil(log2(real(
    to_integer(unsigned(TOP_HALF_ADDRESS))+RAM_BUFF_SIZE))));

  constant MEM_BUFF_SWITCH_TRIP : unsigned(CNT_ADRB - 1 downto 0)
    := to_unsigned(RAM_BUFF_SIZE-MAX_PACKET_SIZE-1, CNT_ADRB);  -- subtract 1 so that BUFF_SIZE of 2048 means 0-2047

  signal base_addr : std_logic_vector(31 downto 0) := START_ADDRESS;

  signal mem_bytes_written : unsigned(CNT_ADRB - 1 downto 0) := (others => '0');

  --------------------------------------------------------------------------------
  -- DMA Clear Signals
  --------------------------------------------------------------------------------

  signal clear_mode     : std_logic := '0';  -- flag while memory is being cleared
  signal clear_valid    : std_logic := '0';  -- tvalid for clearing the memory
  signal clear_ps_mem_r : std_logic := '0';  -- register to make a rising edge sensitive clear_pulse
  signal clear_pulse    : std_logic := '0';  -- single clock wide pulse to clear the memory

  --------------------------------------------------------------------------------
  -- RAM Occupancy Signals
  --------------------------------------------------------------------------------

  signal ram_in_a_buff : std_logic := '1';
  signal ram_in_b_buff : std_logic := '0';

  signal ram_buff_a_occupancy : unsigned(CNT_ADRB-1 downto 0) := (others => '0');  -- occupancy indicator for each buffer
  signal ram_buff_b_occupancy : unsigned(CNT_ADRB-1 downto 0) := (others => '0');  -- occupancy indicator for each buffer

  signal dma_pointer : unsigned(PTR_ADRB-1 downto 0);  -- pointer to the location in memory being written

begin

  assert BUFF_FRAC_DIVISOR rem (WORDS_TO_SEND * 4) = 0
    report "BUFF_FRAC_DIVISOR must be divisible by WORDS_TO_SEND * 4" severity error;

  --------------------------------------------------------------------------------
  -- Copy signals for outputs
  --------------------------------------------------------------------------------

  -- RAM occupancy connections
  process (clk_axi) is
  begin
    if (rising_edge(clk_axi)) then
      ram_buff_a_occupancy_o <= std_logic_vector(resize(ram_buff_a_occupancy, ram_buff_a_occupancy_o'length));
      ram_buff_b_occupancy_o <= std_logic_vector(resize(ram_buff_b_occupancy, ram_buff_b_occupancy_o'length));
    end if;
  end process;

  dma_pointer_o <= std_logic_vector(resize(dma_pointer, dma_pointer_o'length));

  -------------------------------------------------------------------------------
  -- Datamover Commmand Interface Signals
  -------------------------------------------------------------------------------

  --s2mm command signals
  s2mm_cmd_tdata(71 downto 68) <= (others => '0');  --
  s2mm_cmd_tdata(67 downto 64) <= (others => '0');  --
  s2mm_cmd_tdata(63 downto 32) <= saddr;            -- start address
  s2mm_cmd_tdata(31 downto 24) <= (others => '0');  --
  s2mm_cmd_tdata(23)           <= DATA_TYPE;        -- data type
  s2mm_cmd_tdata(22 downto 0)  <= BTT;              -- bytes to transfer

  --s2mm command valid assertion
  s2mm_cmd_tvalid <= '1' when (s2mm_data_state = ASSERT_CMD) else '0';

  -- data is valid when either the output fifo data is valid, or the memory is being cleared
  s2mm_tvalid <= fifo_out_valid_r or clear_valid;

  -------------------------------------------------------------------------------
  -- FIFO Generator
  -------------------------------------------------------------------------------

  u0 : fifo_generator_0
    port map(
      rst           => reset,
      wr_clk        => clk_in,
      rd_clk        => clk_axi,
      din           => daq_busy_in & fifo_in,
      wr_en         => fifo_wr_en,
      rd_en         => fifo_rd_en,
      rd_data_count => fifo_count,
      dout          => fifo_out,
      valid         => fifo_out_valid,
      full          => fifo_full,
      empty         => wfifo_empty,
      prog_full     => wfifo_prog_full,
      prog_empty    => wfifo_prog_empty,
      wr_rst_busy   => wr_rst_busy,
      rd_rst_busy   => rd_rst_busy
      );

  -- mark the daq as busy if either 16 bit word is busy
  daq_busy_xfifo <= fifo_out(16) and fifo_out(33);
  -- concatenate together the two 16 bit words into one 32 bit word
  data_xfifo     <= fifo_out(15 downto 0) & fifo_out(32 downto 17);

  -- add an additional ff stage for timing.. can only use it in some places
  -- though do to the hard-coded latency constraints, see below.

  process (clk_axi) is
  begin
    if (rising_edge(clk_axi)) then
      data_xfifo_r <= data_xfifo;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- Clear Memory Block Process
  --
  -- if asserted, the dma block will loop through its memory and clear everything
  -- back to zero
  --
  -------------------------------------------------------------------------------

  process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then
      if (reset = '1') then
        clear_ps_mem_r <= '0';
        clear_pulse    <= '0';
      else

        -- make a clear pulse that is rising edge sensitive only
        clear_ps_mem_r <= clear_ps_mem;

        if(clear_ps_mem = '1' and clear_ps_mem_r = '0') then
          clear_pulse <= '1';
        elsif(clear_mode = '1') then
          clear_pulse <= '0';
        else
          clear_pulse <= clear_pulse;
        end if;

      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- Post-AXI packet counter
  -------------------------------------------------------------------------------

  --Keep track of packet transfers
  packet_tracker : process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then

      packet_sent_o <= packet_sent;

      if (data_xfifo_r(31 downto 16) = TAIL or
          data_xfifo_r(15 downto 0) = TAIL) then
        packet_is_tail <= '1';
      else
        packet_is_tail <= '0';
      end if;

      if reset = '1' then
        packet_sent <= (others => '0');
      elsif (fifo_rd_en = '1' and packet_is_tail = '1' and packet_sent /= x"FFFFFFFF") then
        packet_sent <= std_logic_vector(unsigned(packet_sent) + 1);
      else
        packet_sent <= packet_sent;
      end if;

    end if;
  end process;

  --------------------------------------------------------------------------------
  -- Buffer Switch Monitor
  --
  -- Provides a set of signals indicating which buffer the logic is in
  --------------------------------------------------------------------------------

  ram_in_b_buff <= not ram_in_a_buff;

  process (clk_axi) is
  begin
    if (rising_edge(clk_axi)) then
      if (saddr < TOP_HALF_ADDRESS) then
        ram_in_a_buff    <= '1';
      else
        ram_in_a_buff    <= '0';
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- DMA Buffer Switching
  -------------------------------------------------------------------------------

  -- Restart address when x address is reached.
  address_pointer : process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then

      if (reset = '1') then
        buff_switch_request <= '0';
      else

        -- switch memory region
        --   - the dma is now writing into the "overflow region"
        --   - as soon as the daq is idle, as indicated by daq_busy_xfifo
        --     (it always goes idle between packets)
        --     the dma controller will jump to the other memory region

        if (daq_busy_xfifo = '0' and
            mem_bytes_written > MEM_BUFF_SWITCH_TRIP and
            buff_switch_request = '0') then

          buff_switch_request <= '1';

        -- if a wipe of the memory is requested, we switch to the 0th address in
        -- the memory region
        elsif ((clear_pulse = '1' and s2mm_data_state = IDLE) or
               (clear_mode = '1' and mem_bytes_written > MEM_BUFF_SWITCH_TRIP)) then
          buff_switch_request <= '1';

        -- nothing requested, just keep going along
        elsif (buff_switch_response = '1') then
          buff_switch_request <= '0';
        end if;

      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- Address Accumulator
  -------------------------------------------------------------------------------

  address_handler : process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then

      mem_bytes_written <= resize(unsigned(saddr) - unsigned(base_addr),
                                           mem_bytes_written'length);

      if (reset = '1') then
        base_addr <= START_ADDRESS;
        saddr     <= START_ADDRESS;
      elsif buff_switch_request = '1' then

        -- jump to opposite half of ring
        if(base_addr = START_ADDRESS)then
          saddr <= TOP_HALF_ADDRESS;
        else
          saddr <= START_ADDRESS;
        end if;

        buff_switch_response <= '1';

      elsif (s2mm_addr_req_posted_reg = '1') then
        saddr                <= std_logic_vector(unsigned(saddr) + unsigned(BTT));
        buff_switch_response <= '0';
      else
        saddr                <= saddr;
        buff_switch_response <= '0';
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- DMA State Machine
  -------------------------------------------------------------------------------

  s2mm_data_interface : process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then

      if (reset = '1') then
        s2mm_allow_addr_req_reg <= '0';
        s2mm_data_state         <= IDLE;
        delay_counter           <= 0;
        fifo_rd_en              <= '0';
        s2mm_tlast              <= '0';
        s2mm_tdata              <= (others => '0');
        clear_mode              <= '0';
      else

        case s2mm_data_state is

          when IDLE =>

            -- Used to control the MM2S in posting an address on the AXI4 Read address
            -- channel. A 1 allows posting and a 0 inhibits posting.
            s2mm_allow_addr_req_reg <= '1';

            -- make sure we have enough words in the FIFO for a burst transfer
            if((unsigned(fifo_count) mod WORDS_TO_SEND) = 0
               and unsigned(fifo_count) /= 0
               and s2mm_cmd_tready = '1') then
              s2mm_data_state <= ASSERT_CMD;
            elsif(clear_pulse = '1' and s2mm_cmd_tready = '1') then
              s2mm_data_state <= ASSERT_CMD;
              clear_mode      <= '1';
            else
              s2mm_data_state <= IDLE;
              fifo_rd_en      <= '0';
            end if;


          when ASSERT_CMD =>

            -- this state asserts s2mm_cmd_tvalid
            s2mm_data_state <= DELAY0;

          when DELAY0 => -- what does this state do??

            -- there is some latency from s_axis_mm2s_cmd_tvalid to m_axi_mm2s_arvalid (8 clocks)?
            -- I guess this just sits and waits a while

            if delay_counter > 20 then
              s2mm_allow_addr_req_reg <= '0';
              delay_counter           <= 0;
              if (clear_mode = '0') then
                s2mm_data_state <= READ_FIFO;
              else
                s2mm_data_state <= CLEAR_MEM;
              end if;
            else
              delay_counter <= delay_counter + 1;
            end if;

          when READ_FIFO =>

            -- copy signals
            s2mm_tdata       <= data_xfifo;
            fifo_out_valid_r <= fifo_out_valid;

            -- sent all WORDS_TO_SEND words, go to DONE state
            if(words_sent_cnt >= WORDS_TO_SEND) then
              words_sent_cnt   <= 0;
              s2mm_tlast       <= '0';
              fifo_rd_en       <= '0';
              fifo_out_valid_r <= '0';
              s2mm_data_state  <= DONE;

              --XXX: Potential to break things if fifo core is modified (certain
              --     options/checkboxes enabled). Hard coded/hand tuned latency
              --     workaround
              --
              --     Do not modify Synchronization Stages in FIFO GUI. It will
              --     break this. make sure to check the Latency in the settings,
              --     if you change it to anything other than 1 then the firmware
              --     may not work
              --
              --     The issue is that, the avoid reading too much data from the
              --     FIFO, rd_en has to be de-asserted early. So, e.g., if it
              --     takes 2 clocks for data to propagate from rd_en to
              --     data_valid, then if you only want to read 16 words (for a
              --     burst) you must de-assert rd_enable 2 clocks before the
              --     16th word.
              --
              ----   Should make the FIFO latency a parameter, and just have
              ----   this subtraction happen automatically.

            -- assert tlast one clock before the last word
            elsif(words_sent_cnt >= WORDS_TO_SEND - 1) then
              words_sent_cnt <= words_sent_cnt + 1;
              fifo_rd_en      <= '0';
              s2mm_tlast      <= '1';

            -- stop reading the FIFO 2 1+FIFO_LATENCY before the last word
            elsif(words_sent_cnt >= WORDS_TO_SEND - FIFO_LATENCY - 1) then
              fifo_rd_en      <= '0';
              words_sent_cnt <= words_sent_cnt + 1;

            --
            elsif(fifo_out_valid = '1') then
              words_sent_cnt <= words_sent_cnt + 1;

            --
            else
              words_sent_cnt <= words_sent_cnt;
              fifo_rd_en      <= '1';
            end if;

            ------------------------------------------------------------------------------
            -- Clear Memory States
            ------------------------------------------------------------------------------

          when CLEAR_MEM =>

            if (words_sent_cnt >= WORDS_TO_SEND) then
              words_sent_cnt  <= 0;
              s2mm_tlast      <= '0';
              clear_valid     <= '0';
              s2mm_data_state <= CONTINUE_CLEAR;
            elsif (words_sent_cnt >= WORDS_TO_SEND - 1) then
              words_sent_cnt <= words_sent_cnt + 1;
              s2mm_tlast     <= '1';
            else
              words_sent_cnt <= words_sent_cnt + 1;
              s2mm_tdata     <= x"00000000";
              clear_valid    <= '1';
            end if;

          when CONTINUE_CLEAR =>

            if (buff_switch_request = '1') then
              s2mm_data_state <= IDLE;
              clear_mode      <= '0';
            elsif(clear_mode = '1')then
              s2mm_allow_addr_req_reg <= '1';
              s2mm_data_state         <= ASSERT_CMD;
            else
              s2mm_data_state <= CONTINUE_CLEAR;
            end if;

          when DONE =>

            s2mm_tlast      <= '0';
            s2mm_data_state <= IDLE;

          when others =>
            s2mm_data_state <= IDLE;

        end case;
      end if;
    end if;
  end process;

  --------------------------------------------------------------------------------
  -- RAM Occupancy
  --
  -- Running count of split buffer fullness in units of 64ths
  -- Also provides integer value of saddr pointer
  --
  -- (only used for readout, not important to the logic here)
  --------------------------------------------------------------------------------

  ram_occupancy : process(clk_axi)
  begin
    if(rising_edge(clk_axi)) then

      dma_pointer <= unsigned(saddr(dma_pointer'range));

      if s2mm_addr_req_posted_reg = '1' then
        if (mem_bytes_written mod BUFF_FRAC_DIVISOR) = 0 then
          if (dma_pointer < unsigned(TOP_HALF_ADDRESS)) then
            ram_buff_a_occupancy <= ram_buff_a_occupancy + 1;
          end if;
          if (dma_pointer >= unsigned(TOP_HALF_ADDRESS)) then
            ram_buff_b_occupancy <= ram_buff_b_occupancy + 1;
          end if;
        end if;
      end if;
      if ram_a_occ_rst = '1' then
        ram_buff_a_occupancy <= (others => '0');
      end if;
      if ram_b_occ_rst = '1' then
        ram_buff_b_occupancy <= (others => '0');
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------
  -- Data Mover IP
  -------------------------------------------------------------------------------

  u1 : axis2aximm
    port map (
      m_axi_s2mm_aclk    => clk_axi,
      m_axi_s2mm_aresetn => not reset,  -- active low
      s2mm_halt          => '0',
      s2mm_dbg_sel       => x"0",

      --s2mm command
      s_axis_s2mm_cmd_tvalid => s2mm_cmd_tvalid,
      s_axis_s2mm_cmd_tready => s2mm_cmd_tready,
      s_axis_s2mm_cmd_tdata  => s2mm_cmd_tdata,
      --s2mm data
      s_axis_s2mm_tdata      => s2mm_tdata,
      s_axis_s2mm_tkeep      => S2MM_TKEEP,
      s_axis_s2mm_tlast      => s2mm_tlast,
      s_axis_s2mm_tvalid     => s2mm_tvalid,
      s_axis_s2mm_tready     => s2mm_tready,

      m_axis_s2mm_cmdsts_awclk   => clk_axi,
      m_axis_s2mm_cmdsts_aresetn => not reset,  -- active low

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

  -------------------------------------------------------------------------------
  -- ILA
  -------------------------------------------------------------------------------

  debug : if (C_DEBUG) generate

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
        probe20 : in std_logic;
        probe21 : in std_logic_vector(15 downto 0);
        probe22 : in unsigned(31 downto 0);
        probe23 : in std_logic;
        probe24 : in std_logic_vector(33 downto 0);
        probe25 : in std_logic_vector(7 downto 0);
        probe26 : in std_logic_vector(5 downto 0)
        );
    end component;

    signal fifo_debug_concat : std_logic_vector(5 downto 0);

  begin

    fifo_debug_concat <= fifo_wr_en & fifo_rd_en & wfifo_empty & '0' & fifo_out_valid & buff_switch_request;

    ila_s2mm_inst : ila_s2mm
      port map(
        clk     => clk_axi,
        probe0  => s2mm_cmd_tvalid,
        probe1  => s2mm_cmd_tready,
        probe2  => s2mm_cmd_tdata,
        probe3  => s2mm_tdata,
        probe4  => s2mm_tkeep,
        probe5  => s2mm_tlast,
        probe6  => s2mm_tvalid,
        probe7  => s2mm_tready,
        probe8  => saddr,
        probe9  => fifo_rd_en,
        probe10 => data_xfifo,
        probe11 => s2mm_allow_addr_req_reg,
        probe12 => s2mm_addr_req_posted_reg,
        probe13 => s2mm_wr_xfer_cmplt_reg,
        probe14 => s2mm_ld_nxt_len_reg,
        probe15 => s2mm_wr_len_reg,
        probe16 => s2mm_err_reg,
        probe17 => m_axis_s2mm_sts_tvalid_reg,
        probe18 => m_axis_s2mm_sts_tdata_reg,
        probe19 => m_axis_s2mm_sts_tkeep_reg(0),
        probe20 => m_axis_s2mm_sts_tlast_Reg,
        probe21 => fifo_in,
        probe22(CNT_ADRB-1 downto 0) => mem_bytes_written,
        probe22(31 downto CNT_ADRB)  => (others => '0'),
        probe23 => daq_busy_xfifo,
        probe24 => fifo_out,
        probe25 => (others => '0'),
        probe26 => fifo_debug_concat
        );
  end generate;

end Behavioral;
