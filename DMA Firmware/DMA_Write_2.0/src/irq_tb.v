`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/03/2019 10:25:00 AM
// Design Name: 
// Module Name: irq_tb
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


module irq_tb();
 
    reg M_AXI_ACLK;
    reg  M_AXI_ARESETN;
    reg D;
    reg [31:0] IRQ_STATUS;
    
    wire Q;
 
    DMA_WRITE_v1_0_IRQ dut(

   .M_AXI_ACLK(M_AXI_ACLK),
    // Global Reset Singal. This Signal is Active Low
   .M_AXI_ARESETN(M_AXI_ARESETN),
   .IRQ_STATUS(IRQ_STATUS),
   .D(D),
   .Q(Q)
    );

    always #2.25 M_AXI_ACLK = ~M_AXI_ACLK;

    initial begin
    M_AXI_ACLK = 0;
    M_AXI_ARESETN = 0;
    IRQ_STATUS = 1;
    #10;
    D = 1;
    M_AXI_ARESETN = 1;
    #9; 
    D = 0;
    #3;
    IRQ_STATUS = 2'b10;
    #10;
    IRQ_STATUS = 2'b01;
    
    end




endmodule
