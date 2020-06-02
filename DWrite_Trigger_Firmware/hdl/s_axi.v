module s_axi#(
		parameter integer S_AXI_LITE_SIZE = 5,
		parameter integer S_AXI_DATA_SIZE = 32 
		)(
		input S_AXI_ACLK,
		input S_AXI_ARESETN,
        //AR
        input  [ 31 : 0] S_AXI_LITE_ARADDR,
        output S_AXI_LITE_ARREADY,
        input  S_AXI_LITE_ARVALID,
        //input  S_AXI_LITE_ARPROT,
        output S_AXI_LITE_RVALID,
        input  S_AXI_LITE_RREADY,
        output [S_AXI_DATA_SIZE - 1: 0] S_AXI_LITE_RDATA,
        //output [1:0] S_AXI_LITE_RRESP,
        //AW
        input  [ 31 : 0] S_AXI_LITE_AWADDR,
        output S_AXI_LITE_AWREADY,
        input  S_AXI_LITE_AWVALID,
        //input  S_AXI_LITE_AWPROT,
        input  S_AXI_LITE_WVALID,
        output S_AXI_LITE_WREADY,
        input  [S_AXI_DATA_SIZE - 1: 0] S_AXI_LITE_WDATA,
        //output [1:0] S_AXI_LITE_BRESP,
        output S_AXI_LITE_BVALID,
        input S_AXI_LITE_BREADY,
		output [S_AXI_DATA_SIZE - 1: 0] status_reg
		);


		//AXI LITE Register instantiation
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg0;
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg1;
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg2;
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg3;
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg4;
		reg [S_AXI_DATA_SIZE - 1: 0] axi_reg5;
		
        reg [ 31 : 0] axi_araddr ;
        reg [ 31 : 0] axi_awaddr ;

        reg [S_AXI_DATA_SIZE - 1: 0] axi_wdata;
        reg [S_AXI_DATA_SIZE - 1: 0] axi_rdata;

        reg awready;
        reg wready;
        reg bvalid;
        reg axi_wen;
        reg arready;
        reg rvalid;
        reg axi_rvalid;

        assign S_AXI_LITE_AWREADY = awready;
        assign S_AXI_LITE_WREADY  = wready;
        assign S_AXI_LITE_BVALID = bvalid;
        assign S_AXI_LITE_ARREADY = arready;
        assign S_AXI_LITE_RVALID = axi_rvalid;
        assign S_AXI_LITE_RDATA = axi_rdata;
        
        assign status_reg  = axi_reg0;
 
                

		//Assert bvalid when BBREADY is available to indicate a successful write.
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            bvalid <= 0;
          else if(S_AXI_LITE_BREADY && ~bvalid)
            bvalid <= 'b1;
          else
            bvalid <= 'b0;


		//Assert awready when AWADDR and WVALID are present.
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            awready <= 'b0;
          else if(S_AXI_LITE_AWVALID && S_AXI_LITE_WVALID && ~awready)
            awready <= 'b1;
          else if(wready)
            awready <= 'b0;
          else
            awready <= awready;


		//latch write address when awready is asserted.
        always@(posedge S_AXI_ACLK)
            if(S_AXI_ARESETN == 'b0)
                axi_awaddr <= 0;
            else if (awready)
                axi_awaddr <= S_AXI_LITE_AWADDR;
            else
                axi_awaddr <= axi_awaddr;


		//Assert wready when WVALID is asserted and awready is present.
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            wready <= 0;
          else if(S_AXI_LITE_WVALID && ~wready && awready)
            wready <= 'b1;
          else
            wready <= 'b0;


		//latch data when wready is asserted.
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0) begin
            axi_wdata <= 0;
            axi_wen <= 0;
          end else if(awready && wready) begin
            axi_wdata <= S_AXI_LITE_WDATA;
            axi_wen <= 'b1;
          end else if(axi_wen)
            axi_wen <= 'b0;
          else begin
            axi_wdata <= axi_wdata;
            axi_wen <= axi_wen;
          end


		//Write into registers when a valid address and valid data is present.
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)begin
		    axi_reg0 <= 0;
		    axi_reg1 <= 0;
		    axi_reg2 <= 0;
		    axi_reg3 <= 0;
		    axi_reg4 <= 0;
		    axi_reg5 <= 0;
		  end else if(axi_wen) begin
		  case (axi_awaddr[ S_AXI_LITE_SIZE - 1 :0])
			6'h00:  axi_reg0<= axi_wdata;
			6'h04:  axi_reg1<= axi_wdata;
			6'h08:  axi_reg2<= axi_wdata;
			6'h0C:  axi_reg3<= axi_wdata;
			6'h10:  axi_reg4<= axi_wdata;
			6'h14:  axi_reg5<= axi_wdata;
		  default: begin
		    axi_reg0 <= axi_reg0;
			axi_reg1 <= axi_reg1;
			axi_reg2 <= axi_reg2;
			axi_reg3 <= axi_reg3;
			axi_reg4 <= axi_reg4;
			axi_reg5 <= axi_reg5;
		   end endcase
		  end


		//Assert arready when ARVALID is asserted, indicating a valid address to read.
        always@(posedge  S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            arready <= 'b0;
          else if(S_AXI_LITE_ARVALID && ~arready)
            arready <= 'b1;
          else
            arready <= 'b0;

		//Latch ARADDR to axi_aradddr register
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            axi_araddr <= 0;
          else if(arready)
            axi_araddr <= S_AXI_LITE_ARADDR;
          else
            axi_araddr <= axi_araddr;

		//Assert rvalid when RREADY and arready are asserted.
        always@(posedge  S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)
            rvalid <= 'b0;
          else if(arready && S_AXI_LITE_RREADY && ~rvalid)
            rvalid <= 'b1;
          else
            rvalid <= 'b0;
            
		//read from registers
        always@(posedge S_AXI_ACLK)
          if(S_AXI_ARESETN == 'b0)begin
            axi_rvalid <= 'b0;
            axi_rdata <= 'b0;
		  end else if(rvalid) begin
		    axi_rvalid <= 'b1;
		  case(axi_araddr[ S_AXI_LITE_SIZE - 1 :0])
		    6'h00:  axi_rdata <= axi_reg0;
			6'h04:  axi_rdata <= axi_reg1; 
			6'h08:  axi_rdata <= axi_reg2;
			6'h0C:  axi_rdata <= axi_reg3;
			6'h10:  axi_rdata <= axi_reg4;
			6'h14:  axi_rdata <= axi_reg5;
		  default: begin 
		    axi_rdata <= axi_rdata;
		    axi_rvalid <= 0;
		  end endcase
	      end else
			 axi_rvalid <= 'b0;
			
		   
endmodule
