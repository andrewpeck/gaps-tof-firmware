module dwrite_trigger#(
    //AXI Lite address offset width
 	parameter integer S_AXI_LITE_SIZE = 5,
    //AXI Lite data size
    parameter integer S_AXI_DATA_SIZE = 32 
)(
	input wire S_AXI_ACLK,
	input wire S_AXI_ARESETN,
    /* AR */
    input  wire [ 31 : 0] S_AXI_LITE_ARADDR,
    output wire S_AXI_LITE_ARREADY,
    input  S_AXI_LITE_ARVALID,
    //input  S_AXI_LITE_ARPROT,
    output wire S_AXI_LITE_RVALID,
    input  wire S_AXI_LITE_RREADY,
    output wire [S_AXI_DATA_SIZE - 1: 0] S_AXI_LITE_RDATA,
    //output [1:0] S_AXI_LITE_RRESP,
    /* AW */
    input  wire [ 31 : 0] S_AXI_LITE_AWADDR,
    output wire S_AXI_LITE_AWREADY,
    input  wire S_AXI_LITE_AWVALID,
    //input  S_AXI_LITE_AWPROT,
    input  wire S_AXI_LITE_WVALID,
    output wire S_AXI_LITE_WREADY,
    input  wire [S_AXI_DATA_SIZE - 1: 0] S_AXI_LITE_WDATA,
    //output [1:0] S_AXI_LITE_BRESP,
    output wire S_AXI_LITE_BVALID,
    input  wire S_AXI_LITE_BREADY,
	output  wire  dtrig_o
	//output  wire  dtrig_ob

);

	wire [31:0] status_reg;
  
     s_axi#(
        .S_AXI_LITE_SIZE(S_AXI_LITE_SIZE),
        .S_AXI_DATA_SIZE(S_AXI_DATA_SIZE) 
     ) d_trig_axi(
         .S_AXI_ACLK(S_AXI_ACLK),
         .S_AXI_ARESETN(S_AXI_ARESETN),
         //AXI LITE Read Interface
        .S_AXI_LITE_ARADDR(S_AXI_LITE_ARADDR),
        .S_AXI_LITE_ARREADY(S_AXI_LITE_ARREADY),
        .S_AXI_LITE_ARVALID(S_AXI_LITE_ARVALID),
         //.S_AXI_LITE_ARPROT(s_axi_lite_arprot),
        .S_AXI_LITE_RVALID(S_AXI_LITE_RVALID),
        .S_AXI_LITE_RREADY(S_AXI_LITE_RREADY),
        .S_AXI_LITE_RDATA(S_AXI_LITE_RDATA),
        //.S_AXI_LITE_RRESP(s_axi_lite_rresp),
         //AXI LITE Write Interface
        .S_AXI_LITE_AWADDR(S_AXI_LITE_AWADDR),
        .S_AXI_LITE_AWREADY(S_AXI_LITE_AWREADY),
        .S_AXI_LITE_AWVALID(S_AXI_LITE_AWVALID),
        //.S_AXI_LITE_AWPROT(s_axi_lite_awprot),
        .S_AXI_LITE_WVALID(S_AXI_LITE_WVALID),
        .S_AXI_LITE_WREADY(S_AXI_LITE_WREADY),
        .S_AXI_LITE_WDATA(S_AXI_LITE_WDATA),
        //.S_AXI_LITE_BRESP(s_axi_lite_bresp),
        .S_AXI_LITE_BVALID(S_AXI_LITE_BVALID),
        .S_AXI_LITE_BREADY(S_AXI_LITE_BREADY),
        .status_reg(status_reg));



drs_trigger d_trig(
	.clk(S_AXI_ACLK),
	.arst(S_AXI_ARESETN),
	.status_reg(status_reg),
	.dtrig_o(dtrig_o)
	//.dtrig_ob(dtrig_ob)
	);
	
endmodule