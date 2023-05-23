set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 66 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property BITSTREAM.CONFIG.M1PIN PULLNONE [current_design]
set_property BITSTREAM.CONFIG.M2PIN PULLNONE [current_design]
set_property BITSTREAM.CONFIG.M0PIN PULLNONE [current_design]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

set_property PACKAGE_PIN M16 [get_ports LEDgreen]
set_property IOSTANDARD LVCMOS33 [get_ports LEDgreen]

#set_property PACKAGE_PIN P10 [get_ports {LEDred}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LEDred}]

#set_property PACKAGE_PIN P17 [get_ports {CLK1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {CLK1}]

## Clock signal from 100MHz TRENZ board clock
# pin P17, bank 14
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports CLK1]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports CLK1]
#create_generated_clock -name CLK2 -multiply_by 2 CLK1

set_property IOSTANDARD LVCMOS33 [get_ports DISC_*]
set_property PULLDOWN true [get_ports DISC_*]

#trigger inputs
set_property PACKAGE_PIN D7 [get_ports {DISC_A[0]}]
set_property PACKAGE_PIN G6 [get_ports {DISC_A[1]}]
set_property PACKAGE_PIN F6 [get_ports {DISC_A[2]}]

set_property PACKAGE_PIN C5 [get_ports {DISC_B[0]}]
set_property PACKAGE_PIN E5 [get_ports {DISC_B[1]}]
set_property PACKAGE_PIN E6 [get_ports {DISC_B[2]}]

set_property PACKAGE_PIN B6 [get_ports {DISC_C[0]}]
set_property PACKAGE_PIN B4 [get_ports {DISC_C[1]}]
set_property PACKAGE_PIN C4 [get_ports {DISC_C[2]}]

set_property PACKAGE_PIN D4 [get_ports {DISC_D[0]}]
set_property PACKAGE_PIN A5 [get_ports {DISC_D[1]}]
set_property PACKAGE_PIN A6 [get_ports {DISC_D[2]}]

set_property PACKAGE_PIN B3 [get_ports {DISC_E[0]}]
set_property PACKAGE_PIN A3 [get_ports {DISC_E[1]}]
set_property PACKAGE_PIN A4 [get_ports {DISC_E[2]}]

set_property PACKAGE_PIN C2 [get_ports {DISC_F[0]}]
set_property PACKAGE_PIN A1 [get_ports {DISC_F[1]}]
set_property PACKAGE_PIN B1 [get_ports {DISC_F[2]}]

set_property PACKAGE_PIN E1 [get_ports {DISC_G[0]}]
set_property PACKAGE_PIN D2 [get_ports {DISC_G[1]}]
set_property PACKAGE_PIN E2 [get_ports {DISC_G[2]}]

set_property PACKAGE_PIN J3 [get_ports {DISC_H[0]}]
set_property PACKAGE_PIN G1 [get_ports {DISC_H[1]}]
set_property PACKAGE_PIN H1 [get_ports {DISC_H[2]}]

set_property PACKAGE_PIN R2 [get_ports {DISC_I[0]}]
set_property PACKAGE_PIN N1 [get_ports {DISC_I[1]}]
set_property PACKAGE_PIN P2 [get_ports {DISC_I[2]}]

set_property PACKAGE_PIN N4 [get_ports {DISC_J[0]}]
set_property PACKAGE_PIN T1 [get_ports {DISC_J[1]}]
set_property PACKAGE_PIN M4 [get_ports {DISC_J[2]}]

set_property PACKAGE_PIN T3 [get_ports {DISC_K[0]}]
set_property PACKAGE_PIN P4 [get_ports {DISC_K[1]}]
set_property PACKAGE_PIN R3 [get_ports {DISC_K[2]}]

set_property PACKAGE_PIN N5 [get_ports {DISC_L[0]}]
set_property PACKAGE_PIN T5 [get_ports {DISC_L[1]}]
set_property PACKAGE_PIN P5 [get_ports {DISC_L[2]}]

set_property PACKAGE_PIN V2 [get_ports {DISC_M[0]}]
set_property PACKAGE_PIN V1 [get_ports {DISC_M[1]}]
set_property PACKAGE_PIN U2 [get_ports {DISC_M[2]}]

set_property PACKAGE_PIN R6 [get_ports {DISC_N[0]}]
set_property PACKAGE_PIN U4 [get_ports {DISC_N[1]}]
set_property PACKAGE_PIN R5 [get_ports {DISC_N[2]}]

set_property PACKAGE_PIN T6 [get_ports {DISC_O[0]}]
set_property PACKAGE_PIN V4 [get_ports {DISC_O[1]}]
set_property PACKAGE_PIN R7 [get_ports {DISC_O[2]}]

set_property PACKAGE_PIN U6 [get_ports {DISC_P[0]}]
set_property PACKAGE_PIN V6 [get_ports {DISC_P[1]}]
set_property PACKAGE_PIN U7 [get_ports {DISC_P[2]}]

#trigger outputs
set_property IOSTANDARD LVCMOS33 [get_ports TRIG_OUT_*]
set_property PACKAGE_PIN N6 [get_ports TRIG_OUT_0]; #pin 9, J2
set_property PACKAGE_PIN V9 [get_ports TRIG_OUT_1]; #pin 7, J2

#set_clock_groups -name tiktok -logically_exclusive -group [get_clocks [list CLK1 [get_clocks -of_objects [get_pins ck/inst/mmcm_adv_inst/CLKOUT0] -filter {IS_GENERATED && MASTER_CLOCK == CLK1}]]]


# i2c
set_property PACKAGE_PIN F4 [get_ports scl]
set_property PACKAGE_PIN E3 [get_ports sda]
set_property IOSTANDARD LVCMOS33 [get_ports scl]
set_property IOSTANDARD LVCMOS33 [get_ports sda]

# constrain the input delays:
set_max_delay -datapath_only \
    -from [get_ports {DISC_*}] 4.9

# constrain the output delay
set_output_delay -clock [get_clocks CLK1] -max 2.000 [get_ports {ext_out[*]}]
