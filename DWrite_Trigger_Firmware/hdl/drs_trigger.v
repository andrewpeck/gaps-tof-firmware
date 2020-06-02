module drs_trigger(
	input wire clk,
	input wire arst,
	input wire [31:0] status_reg,
	output wire dtrig_o
	//output wire dtrig_ob	
);

reg [31:0] counter; 
reg dtrig;

assign dtrig_o  = dtrig;
//assign dtrig_ob = ~dtrig;


/*
OBUFDS dtring_o(
	.I(dtrig),
	.O(dtrig_o),
	.OB(dtrig_ob));

*/

/*
  This is a simple module for a master trigger system.  
  33 Mhz clock.
  
  6ms : counter = 200000
  
*/


localparam threehundred_ns   = 100;
localparam one_ms   = 33333;
localparam three_ms = 100000;
localparam six_ms   = 200000;

/* 100 Hz */
localparam ten_ms   = 333333; 
  

localparam trig_timer = ten_ms;

always@(posedge clk)
  if(arst == 'b0)begin
    counter <= 0;
	dtrig <= 0;
  end else if ((status_reg & 32'h01) == 1)begin
   if(counter >= trig_timer)begin
    dtrig <= 1;
	counter <= 0;
   end else begin
    dtrig <= 0;
	counter <= counter + 1'b1;
   end end else
    counter <= 0;
	
	
  
  endmodule