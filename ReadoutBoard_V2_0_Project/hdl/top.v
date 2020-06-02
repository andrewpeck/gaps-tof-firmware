`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/28/2020 04:01:57 PM
// Design Name: 
// Module Name: top
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


module top
   (DDR_addr,
    DDR_ba,
    DDR_cas_n,
    DDR_ck_n,
    DDR_ck_p,
    DDR_cke,
    DDR_cs_n,
    DDR_dm,
    DDR_dq,
    DDR_dqs_n,
    DDR_dqs_p,
    DDR_odt,
    DDR_ras_n,
    DDR_reset_n,
    DDR_we_n,
    FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp,
    FIXED_IO_mio,
    FIXED_IO_ps_clk,
    FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb,
    adc_data_i,
    clock_i_n,
    clock_i_p,
    drs_addr_o,
    drs_denable_o,
    drs_dtap_i,
    drs_dwrite_o,
    drs_nreset_o,
    drs_plllock_i,
    drs_rsrload_o,
    drs_srclk_o,
    drs_srin_o,
    drs_srout_i,
    gpio_n,
    gpio_p
    //reset_i
    );
    
      inout [14:0]DDR_addr;
      inout [2:0]DDR_ba;
      inout DDR_cas_n;
      inout DDR_ck_n;
      inout DDR_ck_p;
      inout DDR_cke;
      inout DDR_cs_n;
      inout [3:0]DDR_dm;
      inout [31:0]DDR_dq;
      inout [3:0]DDR_dqs_n;
      inout [3:0]DDR_dqs_p;
      inout DDR_odt;
      inout DDR_ras_n;
      inout DDR_reset_n;
      inout DDR_we_n;
      inout FIXED_IO_ddr_vrn;
      inout FIXED_IO_ddr_vrp;
      inout [53:0]FIXED_IO_mio;
      inout FIXED_IO_ps_clk;
      inout FIXED_IO_ps_porb;
      inout FIXED_IO_ps_srstb;
      input [13:0]adc_data_i;
      input clock_i_n;
      input clock_i_p;
      output [3:0]drs_addr_o;
      output drs_denable_o;
      input drs_dtap_i;
      output drs_dwrite_o;
      output drs_nreset_o;
      input drs_plllock_i;
      output drs_rsrload_o;
      output drs_srclk_o;
      output drs_srin_o;
      input drs_srout_i;
      inout [10:0]gpio_n;
      inout [10:0]gpio_p;
     // input reset_i;
      
      wire [14:0]DDR_addr;
      wire [2:0]DDR_ba;
      wire DDR_cas_n;
      wire DDR_ck_n;
      wire DDR_ck_p;
      wire DDR_cke;
      wire DDR_cs_n;
      wire [3:0]DDR_dm;
      wire [31:0]DDR_dq;
      wire [3:0]DDR_dqs_n;
      wire [3:0]DDR_dqs_p;
      wire DDR_odt;
      wire DDR_ras_n;
      wire DDR_reset_n;
      wire DDR_we_n;
      wire FIXED_IO_ddr_vrn;
      wire FIXED_IO_ddr_vrp;
      wire [53:0]FIXED_IO_mio;
      wire FIXED_IO_ps_clk;
      wire FIXED_IO_ps_porb;
      wire FIXED_IO_ps_srstb;
      wire [13:0]adc_data_i;
      wire clock_i_n;
      wire clock_i_p;
      wire [3:0]drs_addr_o;
      wire drs_denable_o;
      wire drs_dtap_i;
      wire drs_dwrite_o;
      wire drs_nreset_o;
      wire drs_plllock_i;
      wire drs_rsrload_o;
      wire drs_srclk_o;
      wire drs_srin_o;
      wire drs_srout_i;
      wire [10:0]gpio_n;
      wire [10:0]gpio_p;
     
      GAPSReadoutv2_0_wrapper  GAPSReadoutv2_0_1
           (.DDR_addr(DDR_addr),
            .DDR_ba(DDR_ba),
            .DDR_cas_n(DDR_cas_n),
            .DDR_ck_n(DDR_ck_n),
            .DDR_ck_p(DDR_ck_p),
            .DDR_cke(DDR_cke),
            .DDR_cs_n(DDR_cs_n),
            .DDR_dm(DDR_dm),
            .DDR_dq(DDR_dq),
            .DDR_dqs_n(DDR_dqs_n),
            .DDR_dqs_p(DDR_dqs_p),
            .DDR_odt(DDR_odt),
            .DDR_ras_n(DDR_ras_n),
            .DDR_reset_n(DDR_reset_n),
            .DDR_we_n(DDR_we_n),
            .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
            .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
            .FIXED_IO_mio(FIXED_IO_mio),
            .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
            .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
            .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
            .adc_data_i_0(adc_data_i),
            .clock_i_n_0(clock_i_n),
            .clock_i_p_0(clock_i_p),
            .drs_addr_o_0(drs_addr_o),
            .drs_denable_o_0(drs_denable_o),
            .drs_dtap_i_0(drs_dtap_i),
            .drs_dwrite_o_0(drs_dwrite_o),
            .drs_nreset_o_0(drs_nreset_o),
            .drs_plllock_i_0(drs_plllock_i),
            .drs_rsrload_o_0(drs_rsrload_o),
            .drs_srclk_o_0(drs_srclk_o),
            .drs_srin_o_0(drs_srin_o),
            .drs_srout_i_0(drs_srout_i),
            .gpio_n_0(gpio_n),
            .gpio_p_0(gpio_p)
         //   .reset_i_0(reset_i)
            );    
    
     
    
endmodule
