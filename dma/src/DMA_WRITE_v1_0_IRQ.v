`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2019 10:12:53 AM
// Design Name: 
// Module Name: DMA_WRITE_v1_0_IRQ
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
// 
//////////////////////////////////////////////////////////////////////////////////


    module DMA_WRITE_v1_0_IRQ(
    // Global Clock Signal.
    input wire  M_AXI_ACLK,
    // Global Reset Singal. This Signal is Active Low
    input wire  M_AXI_ARESETN,
    
    input wire D,
    
    input wire [31:0] IRQ_STATUS,
    
    output reg Q,
    
    output reg [31:0] irq_latency
    );
    
    reg [1:0] irq_sync;
    reg [1:0] CS,NS;
    
 
    
    
   // assign Q = irq_sync[1];
    //666MHz = 1.5ns..
    //Atleast 2x CPU Freq: ~3ns
    
    //PL CLK =  250MHz: 4ns
   /* always@(posedge M_AXI_ACLK) 
        if (M_AXI_ARESETN == 'b0)
            irq_sync <= 0;
        else if(IRQ_STATUS[0] == 'b1)
            irq_sync <= {irq_sync[0], D};
        else
            irq_sync <= 0;
     */       
    always@(posedge M_AXI_ACLK) 
        if (M_AXI_ARESETN == 'b0) begin
            CS = 0;
        end else
            CS = NS;
            
   
    always@(*)  
      begin case(CS) 
        2'b00:begin
             if(IRQ_STATUS[0] == 'b1) begin
                if(D == 'b1) begin
                    NS = 2'b01;
                end else 
                  begin
                    NS = 2'b00;
                   end
                end
             else 
                NS = 2'b00;
              end
        2'b01: begin
               if(IRQ_STATUS[1] == 'b1)  //IRQ ACK
                 begin
                  NS = 2'b00;
                 end 
               else
                 NS = 2'b01;
               end 
        default: NS = 2'b00;
          endcase
          end
                 
       always@(posedge M_AXI_ACLK)
        if(M_AXI_ARESETN == 'b0) begin
            Q <= 'b0;
            irq_latency <= 0;
        end else if(CS == 2'b01) begin
            Q <= 'b1;
            irq_latency <= irq_latency + 'b1;
        end else begin
            Q <= 'b0;
            irq_latency <= 0;
        end
            

           
    
    
endmodule
