------------------------------------------------------------
-- DMA Controller 
------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
 use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity dma_controller is
    generic ( 
        words_to_send  : integer := 16;
        MAX_ADDRESS    : std_logic_vector(31 downto 0)  := x"1080_00000";
        HEAD           : std_logic_vector (15 downto 0) := x"AAAA";
        TAIL           : std_logic_vector (15 downto 0) := x"5555"
    );
   Port ( 
        CLK_IN              : in std_logic;
        CLK_AXI             : in std_logic;
        RST_IN              : in std_logic;
        fifo_in             : in std_logic_vector(31 downto 0);
        fifo_wr_en          : in std_logic;
        fifo_full           : out std_logic;
        
        ----
        -- Datamover AXI4MM Signals
        ---
 
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
 
        ----
        -- DMA AXI4 Lite Registers 
        ---    
        DMA_reg0            : out std_logic_vector(31 downto 0);
        DMA_reg1            : in  std_logic_vector(31 downto 0);
        DMA_reg2            : in  std_logic_vector(31 downto 0);
        DMA_reg3            : in  std_logic_vector(31 downto 0);
        DMA_reg4            : in  std_logic_vector(31 downto 0);
        DMA_reg5            : in  std_logic_vector(31 downto 0)
   );
end dma_controller;

architecture Behavioral of dma_controller is

    component axis2aximm is
    port (
            s2mm_halt : IN STD_LOGIC;
            s2mm_dbg_sel : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
            
            m_axi_s2mm_aclk            : IN STD_LOGIC;
            m_axi_s2mm_aresetn         : IN STD_LOGIC;
            s2mm_err                   : OUT STD_LOGIC;
            m_axis_s2mm_cmdsts_awclk   : IN STD_LOGIC;
            m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
            
            --s2mm Command
            s_axis_s2mm_cmd_tvalid     : IN STD_LOGIC;
            s_axis_s2mm_cmd_tready     : OUT STD_LOGIC;
            s_axis_s2mm_cmd_tdata      : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
            --s2mm Status
             m_axis_s2mm_sts_tvalid     : OUT STD_LOGIC;
            m_axis_s2mm_sts_tready     : IN STD_LOGIC;
             m_axis_s2mm_sts_tdata      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
             m_axis_s2mm_sts_tkeep      : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
             m_axis_s2mm_sts_tlast      : OUT STD_LOGIC;
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
            --s2mm stream data
            s_axis_s2mm_tdata          : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axis_s2mm_tkeep          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            s_axis_s2mm_tlast          : IN STD_LOGIC;
            s_axis_s2mm_tvalid         : IN STD_LOGIC;
            s_axis_s2mm_tready         : OUT STD_LOGIC;
            --------------------------------------
            s2mm_allow_addr_req : IN STD_LOGIC;
            s2mm_addr_req_posted : OUT STD_LOGIC;
            s2mm_wr_xfer_cmplt : OUT STD_LOGIC;
            s2mm_ld_nxt_len : OUT STD_LOGIC;
            s2mm_wr_len : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
        );
    end component;
    
        
    
    component fifo_generator_0 is
    port (
            rst : IN STD_LOGIC;
            wr_clk : IN STD_LOGIC;
            rd_clk : IN STD_LOGIC;
            din : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_en : IN STD_LOGIC;
            rd_en : IN STD_LOGIC;
            dout : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            full : OUT STD_LOGIC;
            empty : OUT STD_LOGIC;
            valid : OUT STD_LOGIC;
            rd_data_count : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
            prog_full : OUT STD_LOGIC;
            prog_empty : OUT STD_LOGIC;
            wr_rst_busy : OUT STD_LOGIC;
            rd_rst_busy :  OUT STD_LOGIC
    );
    end component; 
    
    component axi_bram_ctrl_0 is 
    port (
            s_axi_aclk : IN STD_LOGIC;
            s_axi_aresetn : IN STD_LOGIC;
            s_axi_awaddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
            s_axi_awlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            s_axi_awsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            s_axi_awburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            s_axi_awlock : IN STD_LOGIC;
            s_axi_awcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            s_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            s_axi_awvalid : IN STD_LOGIC;
            s_axi_awready : OUT STD_LOGIC;
            s_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            s_axi_wlast : IN STD_LOGIC;
            s_axi_wvalid : IN STD_LOGIC;
            s_axi_wready : OUT STD_LOGIC;
            s_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            s_axi_bvalid : OUT STD_LOGIC;
            s_axi_bready : IN STD_LOGIC;
            s_axi_araddr : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
            s_axi_arlen : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            s_axi_arsize : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            s_axi_arburst : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
            s_axi_arlock : IN STD_LOGIC;
            s_axi_arcache : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            s_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            s_axi_arvalid : IN STD_LOGIC;
            s_axi_arready : OUT STD_LOGIC;
            s_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            s_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            s_axi_rlast : OUT STD_LOGIC;
            s_axi_rvalid : OUT STD_LOGIC;
            s_axi_rready : IN STD_LOGIC;
            
            bram_rst_a : OUT STD_LOGIC;
            bram_clk_a : OUT STD_LOGIC;
            bram_en_a : OUT STD_LOGIC;
            bram_we_a : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            bram_addr_a : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
            bram_wrdata_a : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            bram_rddata_a : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
       );  
    end component;       
    
    component blk_mem_gen_0 IS
      PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            
            clkb : IN STD_LOGIC;
            rstb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            web : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addrb : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
            dinb : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            rsta_busy : OUT STD_LOGIC;
            rstb_busy : OUT STD_LOGIC
      );
    END component;

     component  ila_s2mm IS
        PORT (
            clk : IN STD_LOGIC;
            probe0 : IN STD_LOGIC;
            probe1 : IN STD_LOGIC;
            probe2 : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
            probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe4 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            probe5 : IN STD_LOGIC;
            probe6 : IN STD_LOGIC;
            probe7 : IN STD_LOGIC;
            probe8 : in std_logic_vector(31 downto 0);
            probe9: in std_logic;
            probe10: in std_logic_vector(31 downto 0);
            probe11 : in std_logic;
            probe12 : in std_logic;
            probe13 : in std_logic;
            probe14  : in std_logic;
            probe15 : in std_logic_vector(7 downto 0);
            probe16: in std_logic;
            probe17: in std_logic;
            probe18: in std_logic_vector(7 downto 0);
            probe19: in std_logic;
            probe20: in std_logic
            
     );
     END component;           
  
    TYPE cmd_state is (IDLE, SET, DONE);
    TYPE data_state is (IDLE, ASSERT_CMD,DELAY0,READ_FIFO, DONE,DELAY1);
     
    
    signal reset_sys                    : std_logic := '0'; 
    signal aresetn                      : std_logic := '1';
    signal RESET_ACTIVE                 : std_logic := '0';
     
 

    
    
    signal s2mm_cmd_state               : cmd_state;
    signal s2mm_data_state              : data_state;

    signal data_counter                 : std_logic_vector(9 downto 0);
     
    --fifo signals
    signal fifo_out                     : std_logic_vector(31 downto 0); 
    signal fifo_count                   : std_logic_vector(9 downto 0);
    signal fifo_rd_en                   : std_logic;
    signal fifo_out_valid               : std_logic;
    signal wfifo_full                   : std_logic;
    signal wfifo_empty                  : std_logic;
    signal wfifo_prog_full              : std_logic;
    signal wfifo_prog_empty             : std_logic;
    signal wr_rst_busy                  : std_logic;
    signal rd_rst_busy                  : std_logic; 
    
    --datamover signals 
    --command port
    signal s2mm_cmd_tvalid              : std_logic; 
    signal s2mm_cmd_tready              : std_logic;
    signal s2mm_cmd_tdata               : std_logic_vector(71 downto 0); 
    
    --data port           
    signal s2mm_tdata                   : std_logic_vector(31 downto 0);
    signal s2mm_tkeep                   : std_logic_vector(3 downto 0);
    signal s2mm_tlast                   : std_logic; 
    signal s2mm_tlast_r1                : std_logic;
    signal s2mm_tlast_r2                : std_logic;
    signal s2mm_tvalid                  : std_logic;
    signal s2mm_tready                  : std_logic;
     
    signal btt                          : std_logic_vector(22 downto 0);
    signal saddr                        : std_logic_vector(31 downto 0);
    signal data_type                    : std_logic;
     
    signal init_cmd                     : std_logic;
    
    signal nrst_i                       : std_logic;
    
    ---
      
    signal delay_counter                : integer := 0;
    signal initial_counter              : integer;
    
 
    
    signal valid_fifo_data              : std_logic_vector(31 downto 0) := (others => '0');
    signal packet_sent                  : std_logic_vector(31 downto 0) := (others => '0'); 

    signal s2mm_allow_addr_req_reg      : std_logic;
    signal s2mm_addr_req_posted_reg     : std_logic;
    signal s2mm_wr_xfer_cmplt_reg       : std_logic;
    signal s2mm_ld_nxt_len_reg          : std_logic;
    signal s2mm_wr_len_reg              : std_logic_vector(7 downto 0) := (others => '0');
    
      
    --datamover status signals
    signal m_axis_s2mm_sts_tvalid_reg   : std_logic; 
    signal m_axis_s2mm_sts_tdata_reg    : STD_LOGIC_VECTOR(7  DOWNTO 0);
    signal m_axis_s2mm_sts_tkeep_reg    : STD_LOGIC_VECTOR(0 DOWNTO 0);
    signal m_axis_s2mm_sts_tlast_Reg    : std_logic;
    signal s2mm_err_reg                 : std_logic   := '0';

    signal reset_pointer_address        : std_logic := '0';

 
    begin 

    --active high reset for FIFO
    nrst_i  <= not aresetn;
    --active low reset for logic
    aresetn <= '0' when RST_IN = '0'  or  reset_sys = '1' else '1';
    
    
    --------------------------------------------------------------------------------------------
    -- Datamover Commmand Interface Signals
    --------------------------------------------------------------------------------------------  
      -- incr = 1, fixed = 0
    data_type <= '1'; 
    
    --bytes to transfer
    btt <= std_logic_vector(to_signed(words_to_send *4,23));
  
    --s2mm command signals  
    s2mm_cmd_tdata(71 downto 68) <=  (others => '0'); 
    s2mm_cmd_tdata(67 downto 64) <=  (others => '0');
    s2mm_cmd_tdata(63 downto 32) <=  saddr;           --start address
    s2mm_cmd_tdata(31 downto 24) <=  (others => '0'); 
    s2mm_cmd_tdata(23)           <= data_type;        --data type
    s2mm_cmd_tdata(22 downto 0)  <= btt;              -- bytes to transfer

 
    --s2mm command valid assertion 
    s2mm_cmd_tvalid <= '1' when (s2mm_data_state = ASSERT_CMD ) else '0';
    
    
    s2mm_tvalid <= fifo_out_valid;
    s2mm_tkeep <= x"F";

    --------------------------------------------------------------------------------------------
    -- FIFO Generator
    --------------------------------------------------------------------------------------------  
    u0: fifo_generator_0  
    port map(
            rst                      => nrst_i,
            wr_clk                   => CLK_IN,
            rd_clk                   => CLK_AXI,
            din                      => fifo_in,
            wr_en                    => fifo_wr_en,
            rd_en                    => fifo_rd_en,
            rd_data_count            => fifo_count,
            dout                     => fifo_out,
            valid                    => fifo_out_valid,
            full                     => wfifo_full,
            empty                    => wfifo_empty,
            prog_full                => wfifo_prog_full,
            prog_empty               => wfifo_prog_empty,
            wr_rst_busy              => wr_rst_busy,
            rd_rst_busy              => rd_rst_busy
    );
     
        ila_s2mm_inst:  ila_s2mm 
        PORT map(
            clk       => CLK_AXI, 
            probe0    => s2mm_cmd_tvalid,
            probe1  => s2mm_cmd_tready,
            probe2  => s2mm_cmd_tdata,
            probe3  => s2mm_tdata,
            probe4  => s2mm_tkeep,
            probe5  => s2mm_tlast,
            probe6  => s2mm_tvalid,
            probe7  => s2mm_tready,
            probe8 => valid_fifo_data,
            probe9 => fifo_rd_en,
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
    
    
 
    --------------------------------------------------------------------------------------------
    -- AXI Control Signals
    --------------------------------------------------------------------------------------------    
    
    DMA_reg0  <= packet_sent;
    reset_sys <= DMA_reg1(0);
     
    --Keep track of packet transfers 
    packet_tracker: process(CLK_AXI)
    begin
        if(rising_edge(CLK_AXI)) then
             if RST_IN = RESET_ACTIVE or reset_sys = '1' then
                packet_sent <= (others => '0');
             elsif (fifo_out(15 downto 0) = TAIL)then 
                packet_sent <= std_logic_vector(unsigned(packet_sent) + 1);
             else 
                packet_sent <= packet_sent;
             end if;
       end if;
    end process;   
      
 
       
    -- Restart address when x address is reached. 
    address_pointer: process(CLK_AXI)
    begin
         if(rising_edge(CLK_AXI)) then
           if aresetn = '0' then 
                reset_pointer_address <= '0';
           elsif ( fifo_out = TAIL and saddr >= MAX_ADDRESS)then
                reset_pointer_address <= '1';
           else
                 reset_pointer_address <= '0';
           end if;
         end if;
    end process; 

    address_handler: process(CLK_AXI)
    begin
         if(rising_edge(CLK_AXI)) then
             if aresetn = '0' or reset_pointer_address = '1' then 
                saddr <= x"10000000";
             elsif (s2mm_addr_req_posted_reg = '1') then
                saddr   <= std_logic_vector(unsigned(saddr) + unsigned(btt));
             else
                saddr <= saddr;
             end if;
         end if;
    end process;
     
    s2mm_data_interface: process(CLK_AXI)
    begin
      if(rising_edge(CLK_AXI)) then
        if aresetn = '0' then  
          s2mm_allow_addr_req_reg <= '0';
          s2mm_data_state <= IDLE; 
          delay_counter   <= 0;
          fifo_rd_en      <= '0'; 
          s2mm_tlast      <= '0';
          s2mm_tdata      <= (others => '0');
        else
          case s2mm_data_state is 
          when IDLE => 
            s2mm_allow_addr_req_reg <= '1'; 
            if((unsigned(fifo_count) mod (words_to_send-1)) = 0 and unsigned(fifo_count) /= 0  and s2mm_cmd_tready = '1' ) then
                 s2mm_data_state <= ASSERT_CMD; 
            else 
                fifo_rd_en <= '0'; 
            end if;
            
          when ASSERT_CMD =>  
                s2mm_data_state <= DELAY0;
                    
          when DELAY0     => 
            if delay_counter > 20 then
                s2mm_allow_addr_req_reg <= '0';
                s2mm_data_state <= READ_FIFO; 
                delay_counter <= 0;
            else 
                delay_counter <=   delay_counter + 1;
            end if;
            
          when READ_FIFO  =>   
          
                  if(unsigned(valid_fifo_data) >= words_to_send) then
                    s2mm_tdata  <= fifo_out; 
                    valid_fifo_data <= (others => '0');
                    s2mm_tlast  <= '1';
                    fifo_rd_en <= '0';                      
                    s2mm_data_state <= DONE; 
                 else 
                    valid_fifo_data <= std_logic_vector(unsigned(valid_fifo_data) + 1);
                    s2mm_tdata  <= fifo_out;
                    fifo_rd_en <= '1'; 
                end if; 
        
          when DONE  => 
               s2mm_tlast   <= '0';
               s2mm_data_state <= IDLE; 
           when others =>  s2mm_data_state <= IDLE;  
          end case;
        end if;
       end if;
       end process;
    

    --------------------------------------------------------------------------------------------
    -- Data Mover IP
    -------------------------------------------------------------------------------------------- 
    u1: axis2aximm 
    port map (
        m_axi_s2mm_aclk             => CLK_AXI,
        m_axi_s2mm_aresetn          => aresetn, 
        s2mm_halt                   => '0',
        s2mm_dbg_sel                => x"0", 
 
        --s2mm command
        s_axis_s2mm_cmd_tvalid      => s2mm_cmd_tvalid,
        s_axis_s2mm_cmd_tready      => s2mm_cmd_tready,
        s_axis_s2mm_cmd_tdata       => s2mm_cmd_tdata,
        --s2mm data
        s_axis_s2mm_tdata           => s2mm_tdata,
        s_axis_s2mm_tkeep           => s2mm_tkeep,
        s_axis_s2mm_tlast           => s2mm_tlast,
        s_axis_s2mm_tvalid          => s2mm_tvalid,
        s_axis_s2mm_tready          => s2mm_tready, 
 
        m_axis_s2mm_cmdsts_awclk    => CLK_AXI,
        m_axis_s2mm_cmdsts_aresetn  => aresetn,
        
        m_axis_s2mm_sts_tvalid      => m_axis_s2mm_sts_tvalid_reg,
        m_axis_s2mm_sts_tready      => '1',
        m_axis_s2mm_sts_tdata       => m_axis_s2mm_sts_tdata_reg, 
        m_axis_s2mm_sts_tkeep       =>m_axis_s2mm_sts_tkeep_reg, 
        m_axis_s2mm_sts_tlast       =>m_axis_s2mm_sts_tlast_reg, 
 
        m_axi_s2mm_awid             => m_axi_s2mm_awid,
        m_axi_s2mm_awaddr           => m_axi_s2mm_awaddr,
        m_axi_s2mm_awvalid          => m_axi_s2mm_awvalid,
        m_axi_s2mm_awlen            => m_axi_s2mm_awlen,
        m_axi_s2mm_awsize           => m_axi_s2mm_awsize,
        m_axi_s2mm_awburst          => m_axi_s2mm_awburst,
        m_axi_s2mm_awprot           => m_axi_s2mm_awprot,
        m_axi_s2mm_awcache          => m_axi_s2mm_awcache,
        m_axi_s2mm_awuser           => m_axi_s2mm_awuser,
        m_axi_s2mm_wdata            => m_axi_s2mm_wdata,
        m_axi_s2mm_wstrb            => m_axi_s2mm_wstrb,
        m_axi_s2mm_wlast            => m_axi_s2mm_wlast,
        m_axi_s2mm_wvalid           => m_axi_s2mm_wvalid,
        m_axi_s2mm_bresp            => m_axi_s2mm_bresp,
        m_axi_s2mm_bvalid           => m_axi_s2mm_bvalid,
        m_axi_s2mm_bready           => m_axi_s2mm_bready, 
        m_axi_s2mm_awready          => m_axi_s2mm_awready, 
        m_axi_s2mm_wready           => m_axi_s2mm_wready,
        s2mm_allow_addr_req         => s2mm_allow_addr_req_reg, 
        s2mm_addr_req_posted        => s2mm_addr_req_posted_reg, 
        s2mm_wr_xfer_cmplt          => s2mm_wr_xfer_cmplt_reg, 
        s2mm_ld_nxt_len             => s2mm_ld_nxt_len_reg, 
        s2mm_wr_len                 => s2mm_wr_len_reg,
        s2mm_err                    => s2mm_err_reg
           
    ); 
end Behavioral;