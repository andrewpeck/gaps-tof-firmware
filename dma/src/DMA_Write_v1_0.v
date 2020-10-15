`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UCLA    
// Engineer: Ismael Garcia
// 
// Create Date: 07/31/2019 06:10:20 PM
// Design Name: 
// Module Name: DMA_Write_v1_0
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// This IP is intended for systems with crossing clock domain, as there's a FIFO in between two systems. 
// EX. 240 MHz and 300 MHz.
// DMA Write IP requires 32 bits of data along with packets of 256 data for a single DMA transfer.
// Each transfer will increment the address by 1KB (0x0400). 
//
 //   System A Clk: 240MHz       System B (DMA) Clk: 300MHz           Processor
//     ___   ___   ___             _   _   _
//   _|   |_|   |_|   |_  FIFO   _| |_| |_| |_                 ->     PS
//
//////////////////////////////////////////////////////////////////////////////////

    module DMA_Write_v1_0 #
    (
        //AXI base address 
        parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'h10000000,
        //AXI Burst Length
        parameter integer C_M00_AXI_BURST_LEN   = 256,
        //AXI ID width
        parameter integer C_M00_AXI_ID_WIDTH    = 1,
        //Master AXI address width
        parameter integer C_M00_AXI_ADDR_WIDTH  = 32,
        //BUSER AXI width
        parameter integer C_M00_AXI_DATA_WIDTH  = 32,
        //WUSER AXI width
        parameter integer C_M00_AXI_AWUSER_WIDTH    = 0,
        //WUSER AXI width
        parameter integer C_M00_AXI_WUSER_WIDTH = 0,
        //BUSER AXI width
        parameter integer C_M00_AXI_BUSER_WIDTH = 0,
        //FIFO write depth
        parameter integer C_FIFO_WR_DEPTH = 32768,
        //FIFO data width
        parameter integer C_FIFO_DATA_SIZE = 32,
        //Address 1073741824 = 1GB
        parameter integer address_Complete = 8192000,  
        //period interrupt when data transfer meets treshold. 
        parameter integer interrupt_treshold = 100,//400KB triggers an interrupt
        
        //AXI Lite address offset width
        parameter integer S_AXI_LITE_SIZE = 5,
        //AXI Lite data size
        parameter integer S_AXI_DATA_SIZE = 32 
        
    )
    ( 
        // Ports of Axi Master Bus Interface M00_AXI
        input wire  m00_axi_aclk,
        input wire  m00_axi_aresetn,
        output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
        output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
        output wire [7 : 0] m00_axi_awlen,
        output wire [2 : 0] m00_axi_awsize,
        output wire [1 : 0] m00_axi_awburst,
        output wire  m00_axi_awlock,
        output wire [3 : 0] m00_axi_awcache,
        output wire [2 : 0] m00_axi_awprot,
        output wire [3 : 0] m00_axi_awqos,
        output wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser,
        output wire  m00_axi_awvalid,
        input wire  m00_axi_awready,
        output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
        output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
        output wire  m00_axi_wlast,
        output wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser,
        output wire  m00_axi_wvalid,
        input wire  m00_axi_wready,
        input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
        input wire [1 : 0] m00_axi_bresp,
        input wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser,
        input wire  m00_axi_bvalid,
        output wire  m00_axi_bready,  
        //output wire burst_transaction_complete,
        input wire wr_aclk,
        input wire [31:0] din_dma, 
        input wire wr_en,
        //output wire [$clog2(C_FIFO_WR_DEPTH) - 1:0]fifo_wr_count,
        output wire fifo_full,
        ////////////////////////////////////////////////////////
        //AXI LITE INTERFACE
        ////////////////////////////////////////////////////////
        //AXI Lite Read Interface
        input  wire  [31: 0] s_axi_lite_araddr,
        output wire  s_axi_lite_arready,
        input  wire  s_axi_lite_arvalid,
        //input  wire  s_axi_lite_arprot,
        output wire  s_axi_lite_rvalid,
        input  wire  s_axi_lite_rready,
        output wire  [S_AXI_DATA_SIZE - 1: 0] s_axi_lite_rdata,
        //output wire  [1:0] s_axi_lite_rresp,
        //AXI Lite Write Interface
        input  wire  [31: 0] s_axi_lite_awaddr,
        output wire  s_axi_lite_awready,
        input  wire  s_axi_lite_awvalid,
        //input  wire  s_axi_lite_awprot,
        input  wire  s_axi_lite_wvalid,
        output wire  s_axi_lite_wready,
        input  wire  [S_AXI_DATA_SIZE - 1: 0] s_axi_lite_wdata,
        //output wire  [1:0] s_axi_lite_bresp,
        output wire  s_axi_lite_bvalid,
        input  wire  s_axi_lite_bready,            
        output wire dma_irq
        /*output wire FourKB_Complete,
        output wire [31:0] irq_latency
        */    
    );
    
         wire [C_FIFO_DATA_SIZE - 1:0] fifo_data;
         wire [$clog2(C_FIFO_WR_DEPTH) - 1:0] fifo_rd_count;
         wire fifo_ren;
         wire fifo_empty;
         wire fifo_valid;
         wire [31:0] DMA_STATUS;
         wire [31:0] DMA_Trigger;
         wire burst_transaction_complete;
         wire trigger_interrupt;
         
   // Instantiation of Axi Bus Interface M00_AXI
    DMA_Write_v1_0_M00_AXI # ( 
        .C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
        .C_M_AXI_WRITE_BURST_LEN(C_M00_AXI_BURST_LEN),
        .C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
        .C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
        .C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
        .C_M_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
        .C_M_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
        .C_M_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH),
        .C_FIFO_WR_DEPTH(C_FIFO_WR_DEPTH),
        .C_FIFO_DATA_SIZE(C_FIFO_DATA_SIZE),   
        .address_Complete(address_Complete),
		 .interrupt_treshold(interrupt_treshold)
        
    ) DMA_Write_v1_0_M00_AXI_inst (
        .M_AXI_ACLK(m00_axi_aclk),
        .M_AXI_ARESETN(m00_axi_aresetn),
        .M_AXI_AWID(m00_axi_awid),
        .M_AXI_AWADDR(m00_axi_awaddr),
        .M_AXI_AWLEN(m00_axi_awlen),
        .M_AXI_AWSIZE(m00_axi_awsize),
        .M_AXI_AWBURST(m00_axi_awburst),
        .M_AXI_AWLOCK(m00_axi_awlock),
        .M_AXI_AWCACHE(m00_axi_awcache),
        .M_AXI_AWPROT(m00_axi_awprot),
        .M_AXI_AWQOS(m00_axi_awqos),
        .M_AXI_AWUSER(m00_axi_awuser),
        .M_AXI_AWVALID(m00_axi_awvalid),
        .M_AXI_AWREADY(m00_axi_awready),
        .M_AXI_WDATA(m00_axi_wdata),
        .M_AXI_WSTRB(m00_axi_wstrb),
        .M_AXI_WLAST(m00_axi_wlast),
        .M_AXI_WUSER(m00_axi_wuser),
        .M_AXI_WVALID(m00_axi_wvalid),
        .M_AXI_WREADY(m00_axi_wready),
        .M_AXI_BID(m00_axi_bid),
        .M_AXI_BRESP(m00_axi_bresp),
        .M_AXI_BUSER(m00_axi_buser),
        .M_AXI_BVALID(m00_axi_bvalid),
        .M_AXI_BREADY(m00_axi_bready),
        .fifo_ren(fifo_ren),
         .fifo_empty(fifo_empty),
        .fifo_valid(fifo_valid),
        .fifo_data(fifo_data),
        .fifo_rd_count(fifo_rd_count),
        .trigger_interrupt(trigger_interrupt),
		.dma_status(DMA_STATUS),
        .dma_trigger_value(DMA_Trigger));
		
             
     reg fifo_clk;
     wire [31:0] fifo_counter;
     reg  [31:0] fifo_din;
     reg  fifo_wr_en;
     wire [S_AXI_DATA_SIZE - 1:0] IRQ_STATUS;
     wire [S_AXI_DATA_SIZE - 1:0] FIFO_COUNTER_STATUS;
     wire fifo_counter_wen;
     
     /*
     FIFO_Counter  fifo_counter_gen(
     .clk(m00_axi_aclk),
     .rst(m00_axi_aresetn),
     .fifo_wen(fifo_counter_wen),
     .en_counter(FIFO_COUNTER_STATUS[1]),
     .fifo_counter(fifo_counter));
     */
     
     
      ila_0 fifo_ila(
       .clk(wr_aclk),
       .probe0(wr_en),
       .probe1(din_dma));
     /*
     ila_0 fifo_ila(
       .clk(m00_axi_aclk),
       .probe0(fifo_counter_wen),
       .probe1(FIFO_COUNTER_STATUS[1]),
       .probe2(fifo_counter));
     */
     /*
     //MUX FIFO Input
     always@(*)
     case(FIFO_COUNTER_STATUS[0])
     1'b0:begin
             fifo_clk   = m00_axi_aclk;
             fifo_wr_en = fifo_counter_wen;
             fifo_din   = fifo_counter;
     end
     1'b1: begin
             fifo_clk   = wr_aclk;
             fifo_wr_en = wr_en;
             fifo_din   = din_dma;
     end
     default: fifo_din = 0;
     endcase
      */
      
     wire fifo_rst;
     assign  fifo_rst = ~m00_axi_aresetn;

//    xpm_fifo_async #(
//        .CDC_SYNC_STAGES(2), // DECIMAL
//        .DOUT_RESET_VALUE("0"), // String
//        .ECC_MODE("ecc"), // String
//        .FIFO_MEMORY_TYPE("auto"), // String
//        .FIFO_READ_LATENCY(1), // DECIMAL
//        .FIFO_WRITE_DEPTH(16384), // DECIMAL
//        .FULL_RESET_VALUE(0), // DECIMAL
//        .PROG_EMPTY_THRESH(10), // DECIMAL
//        .PROG_FULL_THRESH(1024), // DECIMAL
//        .RD_DATA_COUNT_WIDTH(1), // DECIMAL
//        .READ_MODE("std"), // String
//        .RELATED_CLOCKS(0), // DECIMAL
//        .USE_ADV_FEATURES("0707"), // String
//        .WAKEUP_TIME(0), // DECIMAL
//        .READ_DATA_WIDTH(32), // DECIMAL
//        .WRITE_DATA_WIDTH(32), // DECIMAL
//        .WR_DATA_COUNT_WIDTH(1) // DECIMAL
//                        )
//    xpm_fifo_async_inst (
//        .almost_empty  (),             // 1-bit output: Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to empty.
//        .almost_full   (),             // 1-bit output: Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.
//        .data_valid    (fifo_valid),   // 1-bit output: Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).
//        .dbiterr       (),             // 1-bit output: Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.
//        .dout          (fifo_data),    // n-bit output: Read Data: The output data bus is driven when reading the FIFO.
//        .empty         (fifo_empty),   // 1-bit output: Empty Flag: When asserted, this signal indicates that the FIFO is empty. Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.
//        .full          (),             // 1-bit output: Full Flag: When asserted, this signal indicates that the FIFO is full. Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive to the contents of the FIFO.
//        .overflow      (),             // 1-bit output: Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected, because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.
//        .prog_empty    (),             // 1-bit output: Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal to the programmable empty threshold value. It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.
//        .prog_full     (fifo_full),    // 1-bit output: Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal to the programmable full threshold value. It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value. RD_DATA_COUNT_WIDTH
//        .rd_data_count (),             // 1-bit output: Read Data Count: This bus indicates the number of words read from the FIFO.
//        .rd_rst_busy   (),             // 1-bit output: Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.
//        .sbiterr       (),             // 1-bit output: Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.
//        .underflow     (),             // 1-bit output: Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.
//        .wr_ack        (),             // 1-bit output: Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.
//        .wr_data_count (),             // n-bit output: Write Data Count: This bus indicates the number of words written into the FIFO.
//        .wr_rst_busy   (),             // 1-bit output: Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.
//        .din           (din_dma),      // n-bit input: Write Data: The input data bus used when writing the FIFO.
//        .injectdbiterr (1'b0),         // 1-bit input: Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or UltraRAM macros.
//        .injectsbiterr (1'b0),         // 1-bit input: Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or UltraRAM macros.
//        .rd_clk        (m00_axi_aclk), // 1-bit input: Read clock: Used for read operation. rd_clk must be a free running clock.
//        .rd_en         (fifo_ren),     // 1-bit input: Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO. Must be held active-low when rd_rst_busy is active high. .
//        .rst           (fifo_rst),     // 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.
//        .sleep         (),             // 1-bit input: Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.
//        .wr_clk        (wr_aclk),      // 1-bit input: Write clock: Used for write operation. wr_clk must be a free running clock.
//        .wr_en         (wr_en)         // 1-bit input: Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO. Must be held active-low when rst or wr_rst_busy is active high. .
//   );




         fifo_generator_1 DMA_FIFO(
          .rst(fifo_rst),
          .wr_clk(wr_aclk),
          .rd_clk(m00_axi_aclk),
          .din(din_dma),
          .wr_en(wr_en),
          .rd_en(fifo_ren),
          .dout(fifo_data),
          .empty(fifo_empty),
          .valid(fifo_valid),
          .rd_data_count(fifo_rd_count),
          //.wr_data_count(fifo_wr_count),
          .prog_full(fifo_full)
         );

      /*
       fifo_generator_1 DMA_FIFO(
        .rst(fifo_rst),
        .wr_clk(fifo_clk),
        .rd_clk(m00_axi_aclk),
        .din(fifo_din),
        .wr_en(fifo_wr_en),
        .rd_en(fifo_ren),
        .dout(fifo_data),
        .empty(fifo_empty),
        .valid(fifo_valid),
        .rd_data_count(fifo_rd_count),
        //.wr_data_count(fifo_wr_count),
        .prog_full(fifo_full)
     );
     */
            
    
     DMA_WRITE_v1_0_STATUS#(
        .S_AXI_LITE_SIZE(S_AXI_LITE_SIZE),
        .S_AXI_DATA_SIZE(S_AXI_DATA_SIZE) 
     ) IRQ_AXI_LITE(
         .S_AXI_ACLK(m00_axi_aclk),
         .S_AXI_ARESETN(m00_axi_aresetn),
         //AXI LITE Read Interface
        .S_AXI_LITE_ARADDR(s_axi_lite_araddr),
        .S_AXI_LITE_ARREADY(s_axi_lite_arready),
        .S_AXI_LITE_ARVALID(s_axi_lite_arvalid),
         //.S_AXI_LITE_ARPROT(s_axi_lite_arprot),
        .S_AXI_LITE_RVALID(s_axi_lite_rvalid),
        .S_AXI_LITE_RREADY(s_axi_lite_rready),
        .S_AXI_LITE_RDATA(s_axi_lite_rdata),
        //.S_AXI_LITE_RRESP(s_axi_lite_rresp),
         //AXI LITE Write Interface
        .S_AXI_LITE_AWADDR(s_axi_lite_awaddr),
        .S_AXI_LITE_AWREADY(s_axi_lite_awready),
        .S_AXI_LITE_AWVALID(s_axi_lite_awvalid),
        //.S_AXI_LITE_AWPROT(s_axi_lite_awprot),
        .S_AXI_LITE_WVALID(s_axi_lite_wvalid),
        .S_AXI_LITE_WREADY(s_axi_lite_wready),
        .S_AXI_LITE_WDATA(s_axi_lite_wdata),
        //.S_AXI_LITE_BRESP(s_axi_lite_bresp),
        .S_AXI_LITE_BVALID(s_axi_lite_bvalid),
        .S_AXI_LITE_BREADY(s_axi_lite_bready),
        .IRQ_STATUS(IRQ_STATUS),
        .DMA_STATUS(DMA_STATUS),
        .DMA_Trigger(DMA_Trigger),
        .FIFO_COUNTER_STATUS(FIFO_COUNTER_STATUS)
     );
     
     DMA_WRITE_v1_0_IRQ DMA_IRQ(
        .M_AXI_ACLK    (m00_axi_aclk),
        .M_AXI_ARESETN (m00_axi_aresetn), //Global Reset Singal. This Signal is Active Low
        .D             (trigger_interrupt),
        .IRQ_STATUS    (IRQ_STATUS),
        .Q             (dma_irq)
        //.irq_latency (irq_latency)
     );
    endmodule