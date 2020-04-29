
`timescale 1 ns / 1 ps

	module DMA_Write_v1_0_M00_AXI #
	(	//AXI Base Address
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h10000000,
		//256 Burst Length
		parameter integer C_M_AXI_WRITE_BURST_LEN = 256,
 		//Thread ID Width
		parameter integer C_M_AXI_ID_WIDTH	    = 1,
		//Width of Address Bus
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		//Width of Data Bus
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		//Width of User Write Address Bus
		parameter integer C_M_AXI_AWUSER_WIDTH	= 0,
 		//Width of User Write Data Bus
		parameter integer C_M_AXI_WUSER_WIDTH	= 0,
		//Width of User Read Data Bus
		parameter integer C_M_AXI_RUSER_WIDTH	= 0,
		//Width of User Response Bus
		parameter integer C_M_AXI_BUSER_WIDTH	= 0,
		//FIFO Parameters
		parameter integer C_FIFO_WR_DEPTH  = 32768,
               
        parameter integer C_FIFO_DATA_SIZE = 32,
        
		parameter integer four_kilobyte = 4, //
		
		//Address Write Boundary
        parameter integer address_Complete = 36864,
		
		parameter integer interrupt_treshold = 100,
		
		parameter integer interrupt_burst_treshold = interrupt_treshold*four_kilobyte
        
	)
	(
		 
		// Global Clock Signal.
		input wire  M_AXI_ACLK,
		// Global Reset Singal. This Signal is Active Low
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address ID
		output wire [C_M_AXI_ID_WIDTH - 1 : 0] M_AXI_AWID,
		// Master Interface Write Address
		output wire [C_M_AXI_ADDR_WIDTH - 1 : 0] M_AXI_AWADDR,
		// Burst length. The burst length gives the exact number of transfers in a burst
		output wire [7 : 0] M_AXI_AWLEN,
		// Burst size. This signal indicates the size of each transfer in the burst
		output wire [2 : 0] M_AXI_AWSIZE,
		// Burst type. The burst type and the size information, 
		// determine how the address for each transfer within the burst is calculated.
		output wire [1 : 0] M_AXI_AWBURST,
		// Lock type. Provides additional information about the
		// atomic characteristics of the transfer.
		output wire  M_AXI_AWLOCK,
		// Memory type. This signal indicates how transactions
		// are required to progress through a system.
		output wire [3 : 0] M_AXI_AWCACHE,
		// Protection type. This signal indicates the privilege
		// and security level of the transaction, and whether
		// the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Quality of Service, QoS identifier sent for each write transaction.
		output wire [3 : 0] M_AXI_AWQOS,
		// Optional User-defined signal in the write address channel.
		output wire [C_M_AXI_AWUSER_WIDTH-1 : 0] M_AXI_AWUSER,
		// Write address valid. This signal indicates that
		// the channel is signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready. This signal indicates that
		// the slave is ready to accept an address and associated control signals
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data.
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes. This signal indicates which byte
		// lanes hold valid data. There is one write strobe
		// bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write last. This signal indicates the last transfer in a write burst.
		output wire  M_AXI_WLAST,
		// Optional User-defined signal in the write data channel.
		output wire [C_M_AXI_WUSER_WIDTH-1 : 0] M_AXI_WUSER,
		// Write valid. This signal indicates that valid write
		// data and strobes are available
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave
		// can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response.
		input wire [C_M_AXI_ID_WIDTH-1 : 0] M_AXI_BID,
		// Write response. This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Optional User-defined signal in the write response channel
		input wire [C_M_AXI_BUSER_WIDTH-1 : 0] M_AXI_BUSER,
		// Write response valid. This signal indicates that the
        // channel is signaling a valid write response.
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master
        // can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address.
		//FIFO read enable 
        output wire fifo_ren,
        //FIFO empty flag 
        input wire fifo_empty,
        //FIFO Data Valid flag
        input wire fifo_valid,
        //FIFO Output Data
        input wire [C_FIFO_DATA_SIZE - 1:0] fifo_data,
        //FIFO Read Count
        input wire [$clog2(C_FIFO_WR_DEPTH) - 1:0] fifo_rd_count,
         //DMA Burst Flag
        output wire  burst_transaction_complete,
		output wire trigger_interrupt,
        input wire [31:0] dma_status,
        input wire [31:0] dma_trigger_value	
	);       
 	// number of write or read transaction.
	localparam integer C_TRANSACTIONS_NUM = $clog2(C_M_AXI_WRITE_BURST_LEN-1);
	
    /*
    DMA States
    DMA_IDLE:  Module waits until FIFO is full with data in multiples of 4KB 
    DMA_WRITE: Module is writing FIFO data to Processor, a flag is triggered when transfer is complete. 
    */
    localparam integer   DMA_IDLE = 'b0, DMA_WRITE   = 'b1; 
         
	reg dma_state;
    //AXI4 signals
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg axi_awvalid;
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	axi_wdata;
	reg axi_wlast;
	reg axi_wvalid;
	reg axi_bready;
	 
	//write beat count in a burst
	reg [C_TRANSACTIONS_NUM : 0] 	write_index;
  	//size of C_M_AXI_BURST_LEN length burst in bytes
	wire [C_TRANSACTIONS_NUM+4 : 0] 	burst_size_bytes;
   
	reg start_DMAWrite;
 	reg writes_done;
	reg DMA_active;
	wire wnext;
	wire init_pulse;
	
	//Trigger counter for testing. 
	reg  trigger_flag;
	reg  [31:0] trigger_counter;
    wire start_transfer;
    
    wire [1:0]  burst_state;
    
	//FIFO READ DELAY
    reg [3:0] fifo_rd_en_delay;  
	reg [5:0]  KB_Counter;
	reg [31:0] burst_counter;
	
	wire FourKB_Complete;
	
	reg transfer_complete;
  
	//I/O Connections. Write Address (AW)
	assign M_AXI_AWID	= 'b0;
	//The AXI address is a concatenation of the target base address + active offset range
	assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + axi_awaddr;
	//Burst LENgth is number of transaction beats, minus 1
	assign M_AXI_AWLEN	= C_M_AXI_WRITE_BURST_LEN - 1;
	//Size should be C_M_AXI_DATA_WIDTH, in 2^SIZE bytes, otherwise narrow bursts are used
	assign M_AXI_AWSIZE	= $clog2((C_M_AXI_DATA_WIDTH/8)-1);
	//INCR burst type is usually used, except for keyhole bursts
	assign M_AXI_AWBURST  = 2'b01;
	assign M_AXI_AWLOCK	  = 1'b0;
	//Update value to 4'b0011 if coherent accesses to be used via the Zynq ACP port. Not Allocated, Modifiable, not Bufferable. Not Bufferable since this example is meant to test memory, not intermediate cache. 
	assign M_AXI_AWCACHE  = 4'b0010;
	assign M_AXI_AWPROT	  = 3'h0;
	assign M_AXI_AWQOS	  = 4'h0;
	assign M_AXI_AWUSER	  = 'b1;
	assign M_AXI_AWVALID  = axi_awvalid;
	//Write Data(W)
	assign M_AXI_WDATA	= fifo_data;
	//All bursts are complete and aligned in this example
	assign M_AXI_WSTRB	= {(C_M_AXI_DATA_WIDTH/8){1'b1}};
	assign M_AXI_WLAST	= axi_wlast;
	assign M_AXI_WUSER	= 'b0;
	assign M_AXI_WVALID	= wnext;
	
	//Write Response (B)
	assign M_AXI_BREADY	= axi_bready;

	assign burst_size_bytes	= C_M_AXI_WRITE_BURST_LEN * C_M_AXI_DATA_WIDTH/8;
    
	/*Start DMA transfer when FIFO reaches 9216 
      Modify fifo_rd_count threshold value if needed. 
	*/
	assign init_pulse = ((fifo_rd_count >= 14'd1024) && dma_state == DMA_IDLE)?1'b1:1'b0;
	
	assign burst_transaction_complete = writes_done;
	
	
	
    dma_ila debug_dma(
    .clk(M_AXI_ACLK),
    .probe0(M_AXI_AWADDR),
    .probe1(M_AXI_AWREADY),
    .probe2(M_AXI_AWVALID),
    .probe3(M_AXI_WDATA),
    .probe4(M_AXI_WREADY),
    .probe5(M_AXI_WVALID),
    .probe6(M_AXI_WLAST),
    .probe7(M_AXI_BVALID),
    .probe8(M_AXI_BREADY),
    .probe9(fifo_rd_count),
    .probe10(init_pulse),
    .probe11(dma_state),
    .probe12(fifo_ren),
    .probe13(KB_Counter)
    );
	
	
	
	
	
	/*
	  ------------------------------------------------------------------------------------
	                                       Start Transfer
      ------------------------------------------------------------------------------------
	  
	  This process is intended for testing purposes and can be commented out when not needed. This test
	  is a periodic DMA transfer ; the transfer can be delayed by increasing the trigger_counter threshold, or transfer rate 
	  can accelerate by decreasing the trigger_counter threshold.
	  
	
    With a 200MHz AXI Clock
	
	trigger_counter     Trigger Rate
			400,000 	500Hz
		     40,000  	5KHz
			  4,000  	50 KHz
				400  	500KHz
			     40  	5 MHz
    
    
	assign start_transfer = ((trigger_counter >= dma_trigger_value[30:0]) && dma_trigger_value[31])?'b1:'b0;
	
	always @(posedge M_AXI_ACLK) begin
	  if(M_AXI_ARESETN == 0 || start_transfer) 
	    trigger_flag <= 0;
	  else if(dma_status[0] == 'b1 && dma_state == DMA_IDLE)
		trigger_flag <= 'b1;
	  else
		trigger_flag <= trigger_flag;
	  end
		
	always @(posedge M_AXI_ACLK)begin
	  if(M_AXI_ARESETN == 0 || start_transfer )
	    trigger_counter <= 0;
	  else if(~start_transfer && trigger_flag)
	    trigger_counter <= trigger_counter + 'b1;
	  else
		trigger_counter <= trigger_counter;
	  end
	------------------------------------------------------------------------------------
	*/
			  
 
	/*
	  ------------------------------------------------------------------------------------
	                                       Write Address
      ------------------------------------------------------------------------------------
      This process makes sure it provides an address when the memory controller can accept an address. 
      
                ____      ____      ____      ____      ____      ____      ____      ____
      Clk:     |    |____|    |____|    |____|    |____|    |____|    |____|    |____|    |  
         
                  ____________________________                               _________
      AWREADY:                                |_____________________________|
      
                         __________                        
      Start_DMAWrite: __|          |___________________________________________________
      
                                    _________
      axi_awvalid:   ______________|         |________________________________________        
        
                     __________________________________________________________________
      axi_awaddr:    __________32'd0 ________|____________32'd4095_____________________                                                          
     */

	always @(posedge M_AXI_ACLK)begin                                                                                                                                     
	  if (M_AXI_ARESETN == 0)                                          
	    axi_awvalid <= 1'b0;                                                                                                        
	    // If previously not valid , start next transaction                
	  else if (~axi_awvalid && start_DMAWrite)                                                                   
	    axi_awvalid <= 1'b1;                                                                                                         
	    /* Once asserted, VALIDs cannot be deasserted, so axi_awvalid      
	    must wait until transaction is accepted */                         
	  else if (M_AXI_AWREADY && axi_awvalid)                                                                                         
	    axi_awvalid <= 1'b0;                                                                                                           
	  else                                                               
	    axi_awvalid <= axi_awvalid;                                      
	  end                                                                
	     
	/*
 	Address Write is incremented based on data size and burst size . 
 	Ex. 
 	  Write Data size = 32 bits
 	  Burst Size = 256 burst
 	      
 	  4 bytes * 256 burst = 1024
 	      
 	  Each burst would increment by 4096. 
 	      
 	  8192 burst transactions would need to be completed for 8KB. 
 	      
 	  Address Write is re-initialized to 0 when it completes 8KB. 
 	*/      
	always @(posedge M_AXI_ACLK)begin
	  if (M_AXI_ARESETN == 0 || transfer_complete == 1'b1)                                            
	    axi_awaddr <= 'b0;       
	  else if (M_AXI_AWREADY && axi_awvalid)                                                                                    
	    axi_awaddr <= axi_awaddr + burst_size_bytes;                   
	      
	     else                                                               
	    axi_awaddr <= axi_awaddr;                                        
	  end                                                                

	assign wnext = M_AXI_WREADY & fifo_valid; 
	  		                                                                     
	// WVALID logic, similar to the axi_awvalid always block above                      
	always @(posedge M_AXI_ACLK)begin                                                                             
	  if (M_AXI_ARESETN == 0 )                                                               
	    axi_wvalid <= 1'b0;                                                                                                                                   
  	  else if (~axi_wvalid && start_DMAWrite)                                                                        
	    axi_wvalid <= 1'b1;                                                     
	    /* If WREADY and too many writes, throttle WVALID                               
	    Once asserted, VALIDs cannot be deasserted, so WVALID                           
	    must wait until burst is complete with WLAST */                                 
	  else if (wnext && axi_wlast)                                                    
	    axi_wvalid <= 1'b0;                                                           
	  else                                                                            
	    axi_wvalid <= axi_wvalid;
	  end                                                                               
	                                                                                    
	                                                                           
    /*
      ------------------------------------------------------------------------------------
                                              WLAST
      ------------------------------------------------------------------------------------
      WLast Timing Diagram for 256 burst transaction 
      The wlast register is asserted when the system reaches burst size.
                ____      ____      ____      ____      ____      ____      ____      ____
      Clk:     |    |____|    |____|    |____|    |____|    |____|    |____|    |____|    |
                  ______________________________________________________________________
      wready:                                   
                  ______________________________________________________________                       
      dma_active:                                                               |_______
                   _____________________________________
      wvalid:                                           |_______________________________        
        
                    ____________________________________________________________________
      write_index:  _____|__8'd253__|__8'd254_|__8'd255_________________________________
                                               __________
      wlast:       ___________________________|          |______________________________                                                         
	*/
      
	  //Forward movement occurs when the write channel has valid FIFO data and it's ready to accept data.           
	always @(posedge M_AXI_ACLK)begin                                                                             
	  if (M_AXI_ARESETN == 0)                                                                        
	    axi_wlast <= 1'b0;                                                        
	  else if (((write_index == C_M_AXI_WRITE_BURST_LEN-2 && C_M_AXI_WRITE_BURST_LEN >= 2) && wnext && DMA_active) || (C_M_AXI_WRITE_BURST_LEN == 1 ))                                                                              
	    axi_wlast <= 1'b1;                                   
	    // Deassrt axi_wlast when the last write data has been                          
	    // accepted by the slave with a valid response                                  
	  else if (wnext) 
	    axi_wlast <= 1'b0;
	  else if(axi_wlast)
	    axi_wlast <= 1'b0; 
	  else 
 	    axi_wlast <= axi_wlast;                                                       
	     
	  end                   
	  
	
    
	                                                                            
	                                                                                    
      /*
       ------------------------------------------------------------------------------------
                                              write_index
       ------------------------------------------------------------------------------------
       write_index: Register counter used to  keep track of burst count: 
       1:  1
       16: 0 - 15
       256: 0 - 255
       
                  ____      ____      ____      ____      ____      ____      ____      ____
        Clk:     |    |____|    |____|    |____|    |____|    |____|    |____|    |____|    |

                 ____________________________________________________________
     wvalid:                                                                 |_________________                   

                 ________________________________________________________________________________
	w_index:      __8'249__|__8'250___|__8'251__|__8'252__|__8'253__|__8'254_|__8'255___________
      */                                                                                           
    always @(posedge M_AXI_ACLK)begin                                                                             
	  if (M_AXI_ARESETN == 0 || start_DMAWrite == 'b1)    
	    write_index <= 0;                                                           
	  else if (wnext && (write_index != C_M_AXI_WRITE_BURST_LEN-1))                         
	    write_index <= write_index + 1;                                             
	  else                                                                            
	    write_index <= write_index;                                                   
	  end                                                                               
	               
	                                                                                    
	 /*
	 axi_wdata: Register data from FIFO to processor.
	 */        
    always @(posedge M_AXI_ACLK)begin                                                                             
	  if (M_AXI_ARESETN == 0)                                                    
	    axi_wdata <= 'b0;                                                      
	  else if (wnext)                                                                 
	    axi_wdata <= axi_wdata + 'b1;
	  else                                                                            
	    axi_wdata <= axi_wdata;
 	  end        
	    
	      

	/*
	  ------------------------------------------------------------------------------------
                                  Write Response (B) Channel
      ------------------------------------------------------------------------------------
      Assert bready when BVALID is asserted by SLAVE(PS) to indicate a succesful write. 
                         ____      ____      ____      ____      ____      ____      ____
     clk:             __|    |____|    |____|    |____|    |____|    |____|    |____|    |  
     
                                   __________          
     wlast:       ________________|          |___________________________________________   
                                                                  _______________
     bready:      _______________________________________________|               |_______                                |
                                                                         ________                     
     bvalid:      ______________________________________________________|        |_______
	 */

	always @(posedge M_AXI_ACLK)begin                                                                 
	  if (M_AXI_ARESETN == 0 )                                                                                                      
	    axi_bready <= 1'b0;                                                                                                              
	    // accept/acknowledge bresp with axi_bready by the master           
	    // when M_AXI_BVALID is asserted by slave                           
	  else if (M_AXI_BVALID && ~axi_bready)                                                                                          
	    axi_bready <= 1'b1;                                                                                                                  
	    // deassert after one clock cycle                                   
	  else if (axi_bready)                                                
	    axi_bready <= 1'b0;                                             
	    // retain the previous value                                        
	  else                                                                
	    axi_bready <= axi_bready;                                         
	  end                                                                   
	                              
	always@(posedge M_AXI_ACLK)begin 
	 if (M_AXI_ARESETN == 1'b0 )
	   transfer_complete <= 1'b0; 
	 else if(axi_awaddr >= address_Complete && write_index == C_M_AXI_WRITE_BURST_LEN-1)
       transfer_complete <= 1'b1;
     else
       transfer_complete <= 1'b0;
     end             
 
                                          
	 /*
	 Read data from FIFO after AWREADY settles. 
	 */                                                                           
	assign fifo_ren = fifo_rd_en_delay[3];   
     
     /*
        FIFO Read Enable Delay Timing Diagram.   
                        ____      ____      ____      ____      ____      ____      ____
        Clk:         __|    |____|    |____|    |____|    |____|    |____|    |____|    |  
     
                _________________                                         ________________
        AWREADY:                 |_______________________________________|
       
                      (*)Start Write
                        _________________________________________________________________                        
       Delay[0]      __|        
                                   ______________________________________________________ 
       Delay[1]     ______________|        
                                             ____________________________________________        
       Delay[2]     ________________________|         
                                                       __________________________________ 
       Delay[3]     __________________________________|                
                                                       __________________________________         
       REN:  _________________________________________|                
                                                                           _____________________________
      FIFOD:  ____________________________________________________________| D0      |D1        |etc.    |______
    
      */  
                                           
	 /*
	 State Machine to handle DMA data transfer.
	 */
 	always @ ( posedge M_AXI_ACLK)begin                                                                                                     
	  if (M_AXI_ARESETN == 1'b0 )begin                                                                                                 
	  /* reset condition                                                                                  
	     All the signals are assigned default values under reset condition*/                                
	    dma_state      <= DMA_IDLE;
	    fifo_rd_en_delay <= 1'b0;                                                                
	    start_DMAWrite <= 1'b0;                                                                   
	  end else begin                                                                                                                                                                                             
 	    case (dma_state)                                                                               
	      DMA_IDLE:                                                                                                                                   
	        if(init_pulse)begin                                                                                         
	          dma_state  <= DMA_WRITE;                                            
 	        end else begin 
 	          //fifo_rd_en_delay <= 0;
  	          dma_state  <= DMA_IDLE;                                                       
	        end                                                                                                 
	      DMA_WRITE:                                                                                                                                                            
	        if (writes_done)begin                                                                                         
	                dma_state <= DMA_IDLE;        
 	        end else begin                                            
	          dma_state  <= DMA_WRITE;                                                                                        
	        if (~axi_awvalid && ~start_DMAWrite && ~DMA_active)                                                                                                         
	          start_DMAWrite <= 1'b1;           
	          //Reset Delay register when approaching end of Burst Transaction           
	        else if (write_index == C_M_AXI_WRITE_BURST_LEN-2) 
	          fifo_rd_en_delay <= 0; 
	          //Shift FIFO read enable for 5 clocks.
	        else if(DMA_active && write_index <= 9'd05)   
              fifo_rd_en_delay <= {fifo_rd_en_delay[2:0],1'b1}; //5 CLK delay                                                                                                                      
	        else                                                                                                                                                                    
	          start_DMAWrite <= 1'b0;                                                                              
	        end                                                                                 
	        default : dma_state  <= DMA_IDLE;                                                                                                                                                     
	    endcase                                                                                             
	   end                                                                                                   
	end                                                                              
	   
  	 /*
       ------------------------------------------------------------------------------------
                                              DMA_active
       ------------------------------------------------------------------------------------
       The DMA controller is active when state enters DMA_WRITE. It becomes active when burst transaction is complete. 
                       ____      ____      ____      ____      ____      ____      ____
       clk:         __|    |____|    |____|    |____|    |____|    |____|    |____|    |____  
     
                       __________          
       init_pulse:  __|          |___________________________________________________________ 
                                           __________________________________________________
       DMA_active:  ______________________|                                  
       
     */                                     
	always @(posedge M_AXI_ACLK)begin                                                                                                     
	  if (M_AXI_ARESETN == 0)                                                                                 
	    DMA_active <= 1'b0;                                                                           	                                                                                                            
	  else if (start_DMAWrite)                                                                      
	      DMA_active <= 1'b1;                                                                           
	    else if (M_AXI_BVALID && axi_bready)                                                                    
	      DMA_active <= 0;                                                                              
	  end               

	assign trigger_interrupt = (burst_counter >= interrupt_burst_treshold) ? 1'b1: 1'b0;
	assign FourKB_Complete   = (writes_done) ? 1'b1 : 1'b0;
	  
	always@(posedge M_AXI_ACLK)
	  if(M_AXI_ARESETN == 0 || FourKB_Complete == 1'b1)
	    KB_Counter <= 0;
	  else if(M_AXI_BVALID && axi_bready  &&  KB_Counter < 20'd4)
	    KB_Counter  <= KB_Counter + 1'b1;
	  else
	    KB_Counter <= KB_Counter; 
	         
	always@(posedge M_AXI_ACLK)
          if(M_AXI_ARESETN == 0 || trigger_interrupt == 1'b1)
            burst_counter <= 0;
          else if(M_AXI_BVALID && axi_bready  &&  burst_counter < interrupt_burst_treshold)
            burst_counter  <= burst_counter + 1'b1;
          else
            burst_counter <= burst_counter;      
	                                                                                                            
     /*
     ------------------------------------------------------------------------------------
                                    Interrupt
     ------------------------------------------------------------------------------------
     The system asserts an interrupt when it reaches a desired burst write.
     
     Ex. For a 128 bit data, 256 burst. 
         When irq_threshold is set to 50, the system will interrupt every 50 burst write transactions (200KB).
                         ____      ____      ____      ____      ____      ____      ____
     clk:             __|    |____|    |____|    |____|    |____|    |____|    |____|    |  
         
                         __________          
     wlast:     ________|          |______________________________________________________  
                                             __________________
     bready:    ____________________________|                  |__________________________                
                                                       ________                     
     bvalid:      ____________________________________|        |__________________________        
                           _______________________________________________________________
     interrupt_counter:    _______________49___________________|_____50___|______0________
                                                                __________
     interrupt:         _______________________________________|          |_______________ 
     */
	
	assign burst_state = dma_state;                                                                                                         
	always @(posedge M_AXI_ACLK)begin                                                                                                     
	  if (M_AXI_ARESETN == 0)                                                                                 
	    writes_done <= 1'b0;                                                                                                                                                                                       
	    //The writes_done should be associated with a bready response                                           
	  //else if (M_AXI_BVALID && (write_burst_counter[C_NO_BURSTS_REQ]) && axi_bready)
	  else if (M_AXI_BVALID && axi_bready && KB_Counter >= 6'd3)                          
	    writes_done <= 1'b1;
	    //Reset write_done flag when entering a state.
	  else if(burst_state == 2'b00 || burst_state == 2'b01 )
	    writes_done <= 1'b0;                                                                                 
	  else                                                                                                    
	    writes_done <= writes_done;                                                                           
      end         
	    
	endmodule
