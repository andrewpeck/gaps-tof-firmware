module drs_tb;

localparam ADR_TRANSPARENT = 4'b1010;
localparam ADR_READ_SR     = 4'b1011;
localparam ADR_WRITE_SR    = 4'b1101;
localparam ADR_CONFIG      = 4'b1100;
localparam ADR_STANDBY     = 4'b1111;

//--------------------------------------------------------------------------------------------------------------------
// Clock Synthesis
//--------------------------------------------------------------------------------------------------------------------

reg clock33=0;

always @(*) begin
    clock33     <= # 15.000 ~clock33;
end

//--------------------------------------------------------------------------------------------------------------------
// Hold Reset
//--------------------------------------------------------------------------------------------------------------------

parameter STARTUP_RESET_CNT_MAX = 2**7-1;
parameter STARTUP_RESET_BITS    = $clog2 (STARTUP_RESET_CNT_MAX);

reg [STARTUP_RESET_BITS-1:0] startup_reset_cnt = 0;

always @ (posedge clock33) begin
  if (startup_reset_cnt < STARTUP_RESET_CNT_MAX)
    startup_reset_cnt <= startup_reset_cnt + 1'b1;
  else
    startup_reset_cnt <= startup_reset_cnt;
end

wire reset_drs = (startup_reset_cnt < STARTUP_RESET_CNT_MAX);

//--------------------------------------------------------------------------------------------------------------------
// CONFIGURE
//--------------------------------------------------------------------------------------------------------------------

parameter CONFIGURE_CNT_MAX = 1500;
parameter CONFIGURE_BITS    = $clog2 (CONFIGURE_CNT_MAX);

reg [CONFIGURE_BITS-1:0] configure_cnt = 0;

always @ (posedge clock33) begin
  if (reset_drs)
    configure_cnt <= 0;
  else if (configure_cnt < CONFIGURE_CNT_MAX)
    configure_cnt <= configure_cnt + 1'b1;
  else
    configure_cnt <= configure_cnt;
end

reg configured=0;
always @(*) if (configure) configured <= 1'b1;

wire configure = (configure_cnt == CONFIGURE_CNT_MAX-1);

//--------------------------------------------------------------------------------------------------------------------
// START
//--------------------------------------------------------------------------------------------------------------------

parameter STARTUP_CNT_MAX = 2**7-1;
parameter STARTUP_BITS    = $clog2 (STARTUP_CNT_MAX);

reg [STARTUP_BITS-1:0] startup_cnt = 0;

always @ (posedge clock33) begin
  if (!configured)
    startup_cnt <= 0;
  else if (startup_cnt < STARTUP_CNT_MAX)
    startup_cnt <= startup_cnt + 1'b1;
  else
    startup_cnt <= startup_cnt;
end

reg started=0;
always @(*) if (start) started <= 1'b1;

wire start = (startup_cnt == STARTUP_CNT_MAX-1);

//--------------------------------------------------------------------------------------------------------------------
// TRIGGER
//--------------------------------------------------------------------------------------------------------------------

parameter TRIGGER_CNT_MAX = 2**12-1;
parameter TRIGGER_BITS    = $clog2 (TRIGGER_CNT_MAX);

reg [TRIGGER_BITS-1:0] trigger_cnt = 0;

always @ (posedge clock33) begin
  if (!started)
    trigger_cnt <= 0;
  else if (!reset_drs)
    trigger_cnt <= trigger_cnt + 1'b1;
  else
    trigger_cnt <= 0;
end

wire trigger = &trigger_cnt;

//--------------------------------------------------------------------------------------------------------------------
// ADC DATA
//--------------------------------------------------------------------------------------------------------------------

wire [13:0] adc_data = 0;

//--------------------------------------------------------------------------------------------------------------------
// Config
//--------------------------------------------------------------------------------------------------------------------

wire       roi_mode     = 1'b1; // 1=ROI
wire       dmode        = 1'b1; // 1=continuous
wire       reinit       = 1'b0;
wire [8:0] readout_mask = 9'b1;
wire       standby_mode = 1'b0;
wire       transp_mode  = 1'b0;
wire [7:0] drs_config   = 8'hf8 | 8'haa; // top 3 bits must be 1
wire [7:0] chn_config   = 8'h55;

reg [47:0] timestamp=0;
always @(posedge clock33)
  timestamp <= timestamp + 1'b1;

//--------------------------------------------------------------------------------------------------------------------
// DRS
//--------------------------------------------------------------------------------------------------------------------

// outputs
wire [3:0]  drs_addr_o;    // Address Bit Inputs
wire        drs_denable_o; // Domino Enable Input. A low-to-high transition starts the Domino Wave. Set-ting this input low stops the Domino Wave.
wire        drs_dwrite_o;  // Domino Write Input. Connects the Domino Wave Circuit to the Sampling Cells to enable sampling if high.
wire        drs_rsrload_o; // Read Shift Register Load Input
wire        drs_srclk_o;   // Multiplexed Shift Register Clock Input
wire        drs_srclk_en;
wire        drs_srin_o;    // Shared Shift Register Input
wire        drs_wsrin_o;   // Write Shift Register Input. Connected to WSROUT of previous chip for chip daisy-chaining

// inputs
wire       drs_wsrout_i=1'b0;  // Double function: Write Shift Register Output if DWRITE=1, Read Shift Register Output if DWRITE=0.

reg [9:0] stop_cell    = 'hee;
reg [9:0] stop_cell_sr = 'h00;

wire drs_srout_i = stop_cell_sr[9];

always @(negedge drs_srclk_o or posedge drs_rsrload_o) begin

  if (drs_addr_o >= 0 && drs_addr_o <= 9 && drs_rsrload_o) begin
    stop_cell_sr <= stop_cell;
  end
  else begin
    stop_cell_sr <= stop_cell_sr<<1;
  end

end

//----------------------------------------------------------------------------------------------------------------------
// put the drs outputs into a shift register
//----------------------------------------------------------------------------------------------------------------------

reg [7:0] config_reg='hbb;
always @ (negedge drs_srclk_o) begin
  if (drs_addr_o == ADR_CONFIG)
    config_reg <= {config_reg[6:0],drs_srin_o};
end

reg [7:0] wsr_reg='hbb;
always @ (negedge drs_srclk_o) begin
  if (drs_addr_o == ADR_WRITE_SR)
    wsr_reg <= {wsr_reg[6:0],drs_srin_o};
end


drs drs (
  .clock                    (clock33),
  .reset                    (reset_drs),
  .timestamp_i              (timestamp),

  .adc_data_i               (adc_data),

  .drs_ctl_roi_mode         (roi_mode),
  .drs_ctl_dmode            (dmode),
  .drs_ctl_adc_latency      (8),
  .drs_ctl_sample_count_max (1024),
  .drs_ctl_config           (drs_config[7:0]),
  .drs_ctl_chn_config       (chn_config[7:0]),
  .drs_ctl_standby_mode     (standby_mode),
  .drs_ctl_transp_mode      (transp_mode),

  .drs_ctl_start            (start),
  .drs_ctl_reinit           (reinit),
  .drs_ctl_configure_drs    (configure),
  .drs_ctl_wait_vdd_clocks  ('hff), // should be fff
  .drs_ctl_readout_mask     (readout_mask),
  .drs_ctl_spike_removal    (1'b1),

  .drs_addr_o               (drs_addr_o),
  .drs_denable_o            (drs_denable_o),
  .drs_dwrite_o             (drs_dwrite_o),
  .drs_nreset_o             (drs_nreset_o),
  .drs_rsrload_o            (drs_rsrload_o),
  .drs_srclk_en_o           (drs_srclk_en),
  .drs_srout_i              (drs_srout_i),
  .drs_srin_o               (drs_srin_o),

  .rd_data                  (rd_data),
  .rd_enable                (rd_enable),
  .rd_clock                 (rd_clock),


  .trigger_i                (trigger),

  .readout_complete         (readout_complete),

  .busy_o                   (busy)
);

// put srclk on an oddr
ODDR #(                           //
  .DDR_CLK_EDGE("OPPOSITE_EDGE"), // "OPPOSITE_EDGE" or "SAME_EDGE"
  .INIT(1'b0),                    // Initial value of Q: 1'b0 or 1'b1
  .SRTYPE("SYNC")                 // Set/Reset type: "SYNC" or "ASYNC"
) drs_srclk_oddr (                //
  .Q(drs_srclk_o),                // 1-bit DDR output
  .C(clock33),                    // 1-bit clock input
  .CE(1'b1),                      // 1-bit clock enable input
  .D1(1'b1),                      // 1-bit data input (positive edge)
  .D2(1'b0),                      // 1-bit data input (negative edge)
  .R(~drs_srclk_en),              // 1-bit reset
  .S(1'b0)                        // 1-bit set
);

endmodule
