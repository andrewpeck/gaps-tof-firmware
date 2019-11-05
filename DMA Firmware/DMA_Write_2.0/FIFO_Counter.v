`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2019 11:49:01 AM
// Design Name: 
// Module Name: FIFO_Counter
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


module FIFO_Counter(
       input wire clk,
       input wire rst,
       input wire en_counter,
       output reg fifo_wen,
       output reg [31:0] fifo_counter 
    );
     
    always@(posedge clk)
      if(rst == 1'b0)begin
        fifo_wen <= 1'b0;
        fifo_counter <= 0;
      end else if(en_counter) begin
        fifo_wen <= 1'b1;
        fifo_counter <= fifo_counter + 1'b1;
      end else begin
        fifo_wen <= 1'b0;
        fifo_counter <= fifo_counter;
      end   
endmodule
