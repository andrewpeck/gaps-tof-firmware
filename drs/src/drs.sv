// `define DEBUG
// Enable DRS ILAs for now..

// TODO: implement ROI trigger delay
// TODO: figure out what roi old mode does and (possibly?) add it back into the readout format
//       see DRS.cpp ::GetWave function
//       "combine two halfs correctly, see 2048_mode.ppt"
//       seems to be related only to combining two channels in cascade mode
//       and can (probably) be removed if cascading is not used
// TODO: tmr

module drs #(
  parameter TMR_INST      = 0,
  parameter READ_WIDTH    = 14
) (
    //------------------------------------------------------------------------------------------------------------------
    // system
    //------------------------------------------------------------------------------------------------------------------

    // ~ 33MHz ADC clock
    input clock,
    input ila_clock,

    // module reset
    input reset,

    // master trigger
    input trigger_i,

    //------------------------------------------------------------------------------------------------------------------
    // adc
    //------------------------------------------------------------------------------------------------------------------

    input [13:0] adc_data_i, // 14 bit adc data @ 33 MHz

    //------------------------------------------------------------------------------------------------------------------
    // drs control
    //------------------------------------------------------------------------------------------------------------------

    input        diagnostic_mode,

    input        posneg_i,
    input        srout_posneg_i,
    input [2:0]  srout_latency_i,

    input        drs_ctl_spike_removal,           // set 1 for spike removal
    input        drs_ctl_roi_mode,                // set 1 for region of interest mode
    input        drs_ctl_dmode,                   // set 1 = continuous domino, 0=single shot
    input [5:0]  drs_ctl_adc_latency,             // latency from first sr clock to when adc data should be valid
                                                  // correlates with ADC conversion latency
                                                  //
    input [15:0] drs_ctl_wait_vdd_clocks,         //
    input [9:0]  drs_ctl_sample_count_max,        // number of samples to readout
    input [7:0]  drs_ctl_start_timer,             // number of counts from start_running -> running
                                                  //
    input [7:0]  drs_ctl_config,                  // configuration register
                                                  // Bit0  DMODE  Control Domino Mode. A 1 means continuous cycling, a 0 configures a single shot
                                                  // Bit1  PLLEN  Enable bit for the PLL. A 1 enables the operation of the internal PLL
                                                  // Bit2  WSRLOOP  Connect WSRIN internally to WSROUT if set to 1
                                                  // Bit3-7  Reserved  A 1 must always be written to these bit positions
                                                  //
    input       drs_ctl_standby_mode,             // set 1 = shutdown drs4
    input       drs_ctl_transp_mode,              // set 1 = transparent mode
    input       drs_ctl_start,                    // pulse 1 = take the state machine out of idle mode
    input       drs_ctl_reinit,                   // pulse 1 = re-initialize the state machine
    input       drs_ctl_configure_drs,            // pulse 1 = to configure the DRS
                                                  //
    input [7:0] drs_ctl_chn_config,               // Write Shift Register Configuration
                                                  // # of chn | # of cells per ch | bit pattern
                                                  // 8        | 1024              | 11111111 b
                                                  // 4        | 2048              | 01010101 b
                                                  // 2        | 4096              | 00010001 b
                                                  // 1        | 8192              | 00000001
                                                  //
    input [8:0] drs_ctl_readout_mask_i,           // set a bit to '1' to enable readout of its channel

    //------------------------------------------------------------------------------------------------------------------
    // drs io
    //------------------------------------------------------------------------------------------------------------------

    input             drs_srout_i,    // Multiplexed Shift Register Output
    output reg [3:0]  drs_addr_o,     // Address Bit Inputs
    output reg        drs_nreset_o,   // DRS nreset
    output reg        drs_denable_o,  // Domino Enable Input. A low-to-high transition starts the Domino Wave. Set-ting this input low stops the Domino Wave.
    output reg        drs_dwrite_o,   // Domino Write Input. Connects the Domino Wave Circuit to the Sampling Cells to enable sampling if high.
    output reg        drs_rsrload_o,  // Read Shift Register Load Input
    output reg        drs_srclk_en_o, // Multiplexed Shift Register Clock Input
    output reg        drs_srin_o,     // Shared Shift Register Input
    output reg [9:0]  drs_stop_cell_o ,

    //------------------------------------------------------------------------------------------------------------------
    // output fifo
    //------------------------------------------------------------------------------------------------------------------

    output [READ_WIDTH-1:0] fifo_wdata_o,
    output                  fifo_wen_o,

    //------------------------------------------------------------------------------------------------------------------
    // status
    //------------------------------------------------------------------------------------------------------------------

    output reg readout_complete, // goes high 1 clock when readout finishes, for counting
    output     busy_o,           // '1' means DRS cannot accept triggers
    output     idle_o            // '1' means DRS cannot accept triggers
);

//----------------------------------------------------------------------------------------------------------------------
// DRS4 Addresses
//----------------------------------------------------------------------------------------------------------------------

// magic numbers from the drs datasheet
localparam ADR_TRANSPARENT = 4'b1010;
localparam ADR_READ_SR     = 4'b1011;
localparam ADR_WRITE_SR    = 4'b1101;
localparam ADR_CONFIG      = 4'b1100;
localparam ADR_STANDBY     = 4'b1111;

//----------------------------------------------------------------------------------------------------------------------
// Input flops
//----------------------------------------------------------------------------------------------------------------------

reg [13:0] adc_data_neg, adc_data_pos, adc_data;

// take data in on negedge of clock, assuming that adc and fpga clocks are synchronous
always_ff @(negedge clock) begin
  adc_data_neg <= adc_data_i;
end
always_ff @(posedge clock) begin
  adc_data_pos <= adc_data_i;
end

// transfer on flops from negedge to posedge before fifo
always_ff @(posedge clock) begin
  if (posneg_i)
    adc_data <= adc_data_pos;
  else
    adc_data <= adc_data_neg;
end

reg drs_srout_neg;
always @(negedge clock) begin
  drs_srout_neg <= drs_srout_i;
end

wire drs_srout = srout_posneg_i ? drs_srout_i : drs_srout_neg;

//----------------------------------------------------------------------------------------------------------------------
// First/Last/Next Channel Calculators for Mask Based Channel Readout
//----------------------------------------------------------------------------------------------------------------------

reg [3:0] drs_ctl_first_chn;
reg [3:0] drs_ctl_last_chn;
reg [3:0] drs_ctl_next_chn;

reg [8:0] readout_mask_sr;

always_ff @(posedge clock) begin
   drs_ctl_next_chn  <= prienc9(readout_mask_sr);
   drs_ctl_first_chn <= prienc9(drs_ctl_readout_mask_i);
   drs_ctl_last_chn  <= prienc9_rev(drs_ctl_readout_mask_i);
end

//----------------------------------------------------------------------------------------------------------------------
// Other signals
//----------------------------------------------------------------------------------------------------------------------

reg [7:0]  drs_sr_reg='hf8;

// TODO: merge with the other counter
reg [7:0] drs_start_timer = 0; // startup timer to make sure the domino is running before allowing triggers

// reg [7:0]  drs_stat_stop_wsr=0;
// reg        drs_stop_wsr=0;
reg [9:0]  drs_stop_cell=0;
reg [9:0]  drs_stat_stop_cell=0;
reg [9:0] drs_sample_count=0;
reg [15:0] drs_rd_tmp_count=0;
reg [10:0] drs_sr_count=0;

reg [3:0] drs_addr=0;

reg        drs_reinit_request = 0;
reg        drs_old_roi_mode   = 0;

reg [15:0] fifo_wdata=0;
reg        fifo_wen=0;

wire shift_out_config_done = (drs_sr_count == 7);

//----------------------------------------------------------------------------------------------------------------------
// State machine parameters
//----------------------------------------------------------------------------------------------------------------------

typedef enum int unsigned {INIT, IDLE, START_RUNNING, RUNNING, TRIGGER,
    WAIT_VDD, INIT_READOUT, RSR_LOAD, ADC_READOUT, STOP_CELL, SPIKE_REMOVAL, DONE,
    CONF_SETUP, CONF_WRITE, WSR_SETUP, WSR_STROBE, INIT_RSR, STANDBY} state_t;

var state_t drs_readout_state = INIT;

assign busy_o = (drs_readout_state != RUNNING);
assign idle_o = (drs_readout_state == IDLE || drs_readout_state == INIT);

//----------------------------------------------------------------------------------------------------------------------
// Trigger
//----------------------------------------------------------------------------------------------------------------------

reg trigger;
always_ff @(posedge clock) begin
   trigger <= trigger_i && |drs_ctl_readout_mask_i && drs_readout_state == RUNNING;
end

//----------------------------------------------------------------------------------------------------------------------
// State Machine
//----------------------------------------------------------------------------------------------------------------------

always_ff @(posedge clock) begin

  if (reset) begin

  //------------------------------------------------------------------------------------------------------------
  // State
  //------------------------------------------------------------------------------------------------------------
  drs_readout_state <= INIT;

  //------------------------------------------------------------------------------------------------------------
  // Logic
  //------------------------------------------------------------------------------------------------------------

  // drs
  drs_denable_o        <= 0;     // domino waves disabled
  drs_srin_o           <= 0;
  drs_addr_o           <= ADR_STANDBY;  // standby
  drs_rsrload_o        <= 0;
  drs_dwrite_o         <= 0;
  drs_srclk_en_o       <= 0;

  // fifo
  fifo_wdata           <= 0;
  fifo_wen             <= 0;

  // internal
  drs_sr_reg           <= 'hf8;
  drs_start_timer      <= 0;
  // drs_stat_stop_wsr    <= 0;
  // drs_stop_wsr         <= 0;
  drs_stop_cell        <= 0;
  drs_stat_stop_cell   <= 0;
  drs_sr_count         <= 0;
  drs_addr             <= 0;
  drs_old_roi_mode     <= 0;
  drs_sample_count     <= 0;
  drs_rd_tmp_count     <= 0;
  drs_reinit_request   <= 1;
  drs_old_roi_mode     <= 1;
  readout_complete     <= 0;

  end

  else begin

  fifo_wdata        <= 0;
  fifo_wen          <= 0;
  readout_complete  <= 0;

  // Memorize a write access to the bit in the control register that requests a reinitialisation of
  // the DRS readout state machine (drs_ctl_reinit goes high for only one cycle, therefore this
  // "trigger" is memorised).
  if (drs_ctl_reinit)
      drs_reinit_request <= 1;

  case (drs_readout_state)

    // INIT
    INIT: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          // hold reset for 2 clock cycles because of reset period spec in datasheet
          // then go into INIT_RSR or IDLE mode depending on ROI configuration

          if (drs_rd_tmp_count == 1)
            if (drs_ctl_roi_mode == 1)
              drs_readout_state  <= INIT_RSR;
            else
              drs_readout_state  <= IDLE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_srclk_en_o       <= 0;
          drs_nreset_o         <= 0;
          drs_rsrload_o        <= 0;
          drs_reinit_request   <= 0;
          drs_denable_o        <= 0;
          drs_rd_tmp_count     <= drs_rd_tmp_count + 1'b1;


    end // fini

    // IDLE
    IDLE: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_reinit_request)
              drs_readout_state  <= INIT;
          else if (drs_ctl_start)
              drs_readout_state  <= START_RUNNING;

          // initialize
          if (drs_ctl_configure_drs)
              drs_readout_state  <= CONF_SETUP;

          // going out of region of interest mode
          // initialize rsr per Figure 11
          if (drs_old_roi_mode && ~drs_ctl_roi_mode)
              drs_readout_state  <= INIT_RSR;

          // going into region of interest mode
          // clear contents of the rsr to prevent spikes
          if (~drs_old_roi_mode && drs_ctl_roi_mode)
              drs_readout_state  <= SPIKE_REMOVAL;

          if (drs_ctl_standby_mode) begin
              drs_readout_state  <= STANDBY;
          end

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr             <= 0;
          drs_nreset_o         <= 1;
          drs_srclk_en_o       <= 0; // disable clock
          drs_srin_o           <= 0;
          drs_rsrload_o        <= 0;
          drs_start_timer      <= 0;
          drs_rd_tmp_count     <= 0;
          drs_sr_count         <= 0;

          if (drs_ctl_transp_mode)
            drs_addr_o <= ADR_TRANSPARENT;  // transparent mode
          else
            drs_addr_o <= ADR_READ_SR;  // address read shift register

          // detect 1 to 0 transition of readout mode
          // i.e. switching out of roi mode
          drs_old_roi_mode <= drs_ctl_roi_mode;

    end // fini

    // START RUNNING DOMINO
    START_RUNNING: begin


          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_reinit_request)
              drs_readout_state  <= INIT;

          // do not go to running until at least 1.5 domino revolutions
          if (drs_start_timer == drs_ctl_start_timer)  begin // 105 * 30ns <= 3.15us
              drs_readout_state <= RUNNING;
          end else begin
             drs_start_timer <= drs_start_timer + 1;
          end             

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_denable_o   <= 1;   // enable and start domino wave
          drs_dwrite_o    <= 1;   // set drs_write_ff in proc_drs_write

    end // fini

    // WAIT FOR TRIGGER
    RUNNING: begin

          if (drs_reinit_request)
              drs_readout_state  <= INIT;
          if (drs_ctl_standby_mode)
              drs_readout_state  <= IDLE;

          // trigger received or DMODE == 0? If so,
          // stop domino wave & start readout sequence
          // (DMODE=0 means single shot readout)

          if (trigger || drs_ctl_dmode == 1'b0) begin
              drs_readout_state  <= TRIGGER;
              drs_dwrite_o       <= 0;   // set drs_write_ff in proc_drs_write
          end


    end // fini

    // STOP DOMINO
    TRIGGER: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          drs_readout_state <= WAIT_VDD;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr             <= drs_ctl_first_chn;
          readout_mask_sr      <= drs_ctl_readout_mask_i;
          drs_addr_o           <= ADR_READ_SR;  // set address to read shift register for readout
          drs_sample_count     <= 0;
          drs_rd_tmp_count     <= 0;
          drs_stop_cell        <= 0;
        //drs_stop_wsr         <= 0;

    end // fini

    // WAIT FOR SUPPLY TO SETTLE BEFORE READOUT
    WAIT_VDD: begin

          if (drs_reinit_request)
            drs_readout_state <= INIT;

         // drs_readout_state <= INIT_READOUT;
          
          if (drs_rd_tmp_count == drs_ctl_wait_vdd_clocks) begin
            drs_readout_state <= INIT_READOUT;
            drs_rd_tmp_count <= 0;
          end
          else begin
            drs_rd_tmp_count <= drs_rd_tmp_count + 1'b1;
          end
        
          drs_srclk_en_o   <= 0; // disable clock

    end // fini

    // INITIATE READOUT
    INIT_READOUT: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_reinit_request)
              drs_readout_state <= INIT;
          else
              drs_readout_state <= RSR_LOAD;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_srclk_en_o   <= 0;    // disable clock
          drs_addr_o <= drs_addr; // select channel for readout

    end // fini

    // load RSR
    // put in a separate state from INIT to respect addr to rsrload setup time
    RSR_LOAD: begin

          // It stores the cell number where the sampling has been stopped and
          // encodes this position in a 10 bit binary number ranging from 0 to
          // 1023. This encoded position is clocked out to SROUT on the first
          // ten readout clock cycles, as can be seen in Figure 15. The rising
          // edge of the RSRLOAD signal outputs the MSB, while the falling edges
          // of the SRCLK signal reveal the following bits up to the LSB.

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_reinit_request)
              drs_readout_state <= INIT;
          else
              drs_readout_state <= ADC_READOUT;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          if (drs_ctl_roi_mode)
            drs_rsrload_o <= 1;

    end // fini

    // READOUT ADC
    ADC_READOUT: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_reinit_request)
              drs_readout_state <= INIT;

          // All cells & channels of DRS chips read ?
          if (drs_sample_count==drs_ctl_sample_count_max) begin
            if (drs_addr==drs_ctl_last_chn)
               drs_readout_state <= STOP_CELL;
           end

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          // run e.g. 1024 sr clocks to get the data out of the drs
          if (drs_rd_tmp_count <= {6'b0, drs_ctl_sample_count_max})
            drs_srclk_en_o <= 1; // enable clock
          else
            drs_srclk_en_o <= 0; // disable clock

          drs_rsrload_o  <= 0;

          drs_rd_tmp_count <= drs_rd_tmp_count + 1'b1;

          // clock in the first 10 bits to get the stop cell
          if (drs_rd_tmp_count < (srout_latency_i+10)) begin
            drs_stop_cell[0]   <= drs_srout;
            drs_stop_cell[9:1] <= drs_stop_cell[8:0];
          end

          // If the DRS4 is configured for channel cascading or daisy-
          //   chaining, it is necessary to know which the current chan-
          //   nel is where the sampling has been stopped. This can be
          //   determined by addressing the Write Shift Register with
          // A3-A0 = 1101 b  and by applying clock pulses to the
          // SRCLK input. If the DRS4 is configured in single chan-
          //   nel mode and the sampling stopped at channel i, then 8-i
          //   clock pulses will reveal the 1 at the WSROUT and the
          //   SROUT outputs.

          //if (drs_rd_tmp_count == 2 && (drs_addr == drs_ctl_first_chn))
          //  drs_stop_wsr <= drs_srout_i;   // sample last bit of WSR for first channel


          // ADC delivers data at its outputs with 7 clock cycles delay
          // with respect to its external clock pin
          if (drs_rd_tmp_count > {10'b0, drs_ctl_adc_latency}) begin

             if (diagnostic_mode)
               fifo_wdata[13:0] <= {4'b0, drs_sample_count};
             else
               fifo_wdata[13:0]  <= adc_data[13:0];  // ADC data

            fifo_wen          <= 1'b1;
            drs_sample_count  <= drs_sample_count + 1'b1;
          end

          // pick a random clock to update the sr and lookup the next channel
          if (drs_sample_count == 1) begin
            readout_mask_sr[8:0] <= readout_mask_sr & (~(1 << drs_ctl_next_chn));
          end

          // finished
          if (drs_sample_count == drs_ctl_sample_count_max) begin
            drs_sample_count   <= 0;
            drs_rd_tmp_count   <= 0;

            // write stop cell into register
            if (drs_addr == drs_ctl_first_chn)
              drs_stat_stop_cell <= drs_stop_cell;
            // drs_stat_stop_wsr  <= drs_stop_wsr;

            // increment channel address
            // bit mask based "skip" to only readout enabled channels with next channel lookahead
             if (drs_addr != drs_ctl_last_chn) begin
                drs_addr_o        <= drs_ctl_next_chn;
                drs_addr          <= drs_ctl_next_chn;
             end else begin
                drs_addr             <= 0;
                drs_addr_o           <= 0;
                readout_mask_sr[8:0] <= 0;
             end
          end

    end // fini

    // APPEND THE STOP CELL
    STOP_CELL: begin

       //------------------------------------------------------------------------------------------------------------
       // State
       //------------------------------------------------------------------------------------------------------------

       drs_readout_state <= DONE;


       //------------------------------------------------------------------------------------------------------------
       // Logic
       //------------------------------------------------------------------------------------------------------------

       drs_stop_cell_o <= drs_stat_stop_cell;
       fifo_wen        <= 0;

    end // fini

    // FINISH READOUT
    DONE: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_ctl_spike_removal) begin
              drs_readout_state    <= SPIKE_REMOVAL;
          end
          else begin
              drs_readout_state    <= START_RUNNING;
          end

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          readout_complete     <= 1;
          fifo_wen             <= 0;
          drs_dwrite_o         <= 1; // to keep chip "warm"

    end // fini

    // Clear the address read shift register to remove spikes, see elog
    // https://elog.psi.ch/elogs/DRS4+Forum/697
    SPIKE_REMOVAL: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_rd_tmp_count==1024)begin
            drs_readout_state    <= START_RUNNING;
          end
          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_rd_tmp_count <= drs_rd_tmp_count + 1'b1;
          drs_addr_o       <= ADR_READ_SR;
          fifo_wen         <= 0;
          drs_srin_o       <= 0;      // Shared Shift Register Input

          if (drs_rd_tmp_count < 1024)
            drs_srclk_en_o   <= 1;
          else
            drs_srclk_en_o   <= 0;

    end // fini

    //----------------------------------------------------------------------------------------------------------------
    // Configure
    //----------------------------------------------------------------------------------------------------------------

    // set-up of configuration register
    CONF_SETUP: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          drs_readout_state    <= CONF_WRITE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr_o       <= ADR_CONFIG;             // address config register
          drs_srclk_en_o   <= 1;                      // enable clock
          drs_sr_count     <= 0;                      //
          drs_sr_reg       <= 8'hf8 | drs_ctl_config; // c.f. drs manual, The unused bits must but always be 1.
          drs_srin_o       <= 1;                      // shift out 7 bits MSB first; bit 7 must ALWAYS be 1

    end // fini


    // write configuration register to chip
    CONF_WRITE: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (shift_out_config_done)
              drs_readout_state <= WSR_SETUP;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_srclk_en_o   <= 1;                // enable clock

          drs_sr_count     <= drs_sr_count + 1; //
          drs_sr_reg[7:1]  <= drs_sr_reg[6:0];  // shift out 7 bits MSB first
          drs_srin_o       <= drs_sr_reg[7];    //

          if (shift_out_config_done)
              drs_srclk_en_o   <= 0; // disable clock

    end // fini

    // A Write Shift Register containing 8 bits is used to activate channel 0 to 7. Channel 8 is
    // always active and can be used to digitize an external reference clock. The bits are shifted
    // by one position on each revolution of the domino wave. If this register is loaded with 1’s,
    // all channels are active all the time, and the DRS4 works like hav- ing 8 independent
    // channels. The other extreme is a single 1 loaded into the register. This 1 is clocked through
    // all 8 positions consecutively. It then shows up at the WSROUT output and can be fed back into
    // the shift register via the WSRIN input or internally by setting WSRLOOP in the Configuration
    // Register to 1 to form a cyclic operation. This means that on the first domino revolution the
    // first channel is active; on the second domino revolution the second channel is active and so
    // on. If the input signal gets fanned out into each of the 8 channels, the DRS4 chip works like
    // having a single channel with 8 times the sampling depth. set address to 1101 ("address write
    // shift register")

    //----------------------------------------------------------------------------------------------------------------
    // Write to Shift register
    //----------------------------------------------------------------------------------------------------------------

    // set-up of write shift register
    WSR_SETUP: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          drs_readout_state <= WSR_STROBE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr_o       <= ADR_WRITE_SR;          // address write shift register
          drs_srclk_en_o   <= 1;                     // enable clock
          drs_sr_count     <= 0;                     //
          drs_sr_reg       <= drs_ctl_chn_config;    // copy configuration into output shift register
          drs_srin_o       <= drs_ctl_chn_config[7]; // shift out 7 bits MSB first

    end // fini

    // write shift register to chip
    WSR_STROBE: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (shift_out_config_done)
              drs_readout_state <= IDLE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_sr_count     <= drs_sr_count + 1;
          drs_srclk_en_o   <= 1; // enable clock
          drs_sr_reg[7:1]  <= drs_sr_reg[6:0];
          drs_srin_o       <= drs_sr_reg[7];

          if (shift_out_config_done)
            drs_srclk_en_o   <= 0; // disable clock

    end // fini

    // initialize read shift register by putting a single '1' bit into the read shift register
    //
    // To start the full readout mode, the Read Shift Register has to be initialized by clocking a
    // "1" into the first cell. This is achieved by applying address 1011 b at the address input
    // A3-A0 and issuing 1024 clock cycles of SRCLK, where only during the last one SRIN=1 is
    // applied
    //
    // https://elog.psi.ch/elogs/DRS4+Forum/163
    //
    // There are two readout modes "Full Readout Mode" and  "ROI mode".
    //
    //   In the Full Readout Mode, the Read Shift Register has to be initialized before the first
    //   readout by applying the sequence shown in Figure 11 in the data sheet. This clears the full
    //   shift register and sets the first cell to "1". In principle in the following events one
    //   applies each time 1024 clocks. Since the shift register is circula, the single "1" rotates
    //   through the shift register and is at the same position after 1024 clocks. So in principle
    //   the register does not have to be re-initialized. To be hones I have never tried this
    //   myself, so I'm not completely sure if that works.

    //   In the ROI mode, you initialize the Read Shift Register by a single RSRLOAD pulse as shown
    //   in Figure 15. Since the inverter chain stops at different positions in each event, this
    //   pulse has to be applied before each event. The SROUT bits will then tell you where the
    //   inverter chain has been stopped.

    //   Most people I know of use the ROI mode, since the initialization is much simpler (just a
    //   single pulse).


    INIT_RSR: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (drs_sr_count == 1025)
              drs_readout_state  <= IDLE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr_o       <= ADR_READ_SR; // address read shift register

          drs_sr_count     <= drs_sr_count + 1'b1;
          drs_srin_o       <= (drs_sr_count==1025);
          drs_srclk_en_o   <= (drs_sr_count > 0 && drs_sr_count < 1025);


    end // fini

    STANDBY: begin

          //------------------------------------------------------------------------------------------------------------
          // State
          //------------------------------------------------------------------------------------------------------------

          if (!drs_ctl_standby_mode)
            drs_readout_state <= IDLE;

          //------------------------------------------------------------------------------------------------------------
          // Logic
          //------------------------------------------------------------------------------------------------------------

          drs_addr_o <= ADR_STANDBY; // standby mode

    end // fini

    default:

      drs_readout_state <= START_RUNNING;

    endcase
  end // end !reset
end // and always

//----------------------------------------------------------------------------------------------------------------------
// Output FIFO
//----------------------------------------------------------------------------------------------------------------------

assign fifo_wdata_o = fifo_wdata[READ_WIDTH-1:0];
assign fifo_wen_o   = fifo_wen;

//------------------------------------------------------------------------------
// ILA
//------------------------------------------------------------------------------   

`ifdef DEBUG
  ila_drs ila_drs_inst (
    .clk     (ila_clock),
    .probe0  (reset),
    .probe1  (trigger_i),
    .probe2  (adc_data),
    .probe3  (drs_ctl_roi_mode),
    .probe4  (drs_ctl_dmode),
    .probe5  (drs_ctl_adc_latency[5:0]),
    .probe6  (drs_ctl_wait_vdd_clocks[15:0]),
    .probe7  (drs_stat_stop_cell[9:0]),
    .probe8  (drs_ctl_config[7:0]),
    .probe9  (drs_ctl_standby_mode),
    .probe10 (drs_ctl_transp_mode),
    .probe11 (drs_ctl_start),
    .probe12 (drs_ctl_reinit),
    .probe13 (drs_ctl_configure_drs),
    .probe14 (drs_ctl_chn_config [7:0]),
    .probe15 (drs_ctl_readout_mask_i[8:0]),
    .probe16 (drs_srout),
    .probe17 (drs_addr_o[3:0]),
    .probe18 (drs_denable_o),
    .probe19 (drs_dwrite_o),
    .probe20 (drs_rsrload_o),
    .probe21 (drs_srclk_en_o),
    .probe22 (drs_srin_o),
    .probe23 (clock),
    .probe24 (fifo_wdata_o[13:0]),
    .probe25 (fifo_wen_o),
    .probe26 (drs_srout_neg),
    .probe27 (drs_readout_state[4:0]),
    .probe28 (drs_rd_tmp_count[15:0]),
    .probe29 (drs_stop_cell[9:0]),
    .probe30 (drs_ctl_last_chn),
    .probe31 (drs_ctl_first_chn),
    .probe32 (drs_ctl_next_chn),
    .probe33 (drs_addr),
    .probe34 (readout_mask_sr)
  );
`endif

//------------------------------------------------------------------------------
// Helper Functions
//------------------------------------------------------------------------------   

function [3:0] prienc9_rev;
 input [8:0] select;
 reg   [3:0] out;
 begin
   casex(select)
     9'b1xxxxxxxx: out = 4'h8;
     9'b01xxxxxxx: out = 4'h7;
     9'b001xxxxxx: out = 4'h6;
     9'b0001xxxxx: out = 4'h5;
     9'b00001xxxx: out = 4'h4;
     9'b000001xxx: out = 4'h3;
     9'b0000001xx: out = 4'h2;
     9'b00000001x: out = 4'h1;
     9'b000000001: out = 4'h0;
     default: out = 4'h0;
   endcase
   prienc9_rev = out ;
 end
endfunction

function [3:0] prienc9;
 input [8:0] select;
 reg   [3:0] out;
 begin
   casex(select)
     9'bxxxxxxxx1: out = 4'h0;
     9'bxxxxxxx10: out = 4'h1;
     9'bxxxxxx100: out = 4'h2;
     9'bxxxxx1000: out = 4'h3;
     9'bxxxx10000: out = 4'h4;
     9'bxxx100000: out = 4'h5;
     9'bxx1000000: out = 4'h6;
     9'bx10000000: out = 4'h7;
     9'b100000000: out = 4'h8;
     default: out = 4'h0;
   endcase
   prienc9 = out ;
 end
endfunction

//----------------------------------------------------------------------------------------------------------------------
endmodule
//----------------------------------------------------------------------------------------------------------------------
