## Arty Board Constraints

## Clock
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports {i_clk}];
create_clock -add -name sys_clk_pin -period 10.00 \
    -waveform {0 5} [get_ports {i_clk}];

## Buttons
set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports {i_arst_n}];

## Switches  
set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {i_sw[0]}];
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {i_sw[1]}];
set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {i_sw[2]}];
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {i_sw[3]}];

## LEDs
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { o_led[0] }]; #IO_L24N_T3_35 Sch=led[4]
set_property -dict { PACKAGE_PIN J5    IOSTANDARD LVCMOS33 } [get_ports { o_led[1] }]; #IO_25_35 Sch=led[5]
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { o_led[2] }]; #IO_L24P_T3_A01_D17_14 Sch=led[6]
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { o_led[3] }]; #IO_L24N_T3_A00_D16_14 Sch=led[7]
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { o_led[4] }]; #IO_L24P_T3_35 Sch=led3_g
set_property -dict { PACKAGE_PIN J2    IOSTANDARD LVCMOS33 } [get_ports { o_led[5] }]; #IO_L22N_T3_35 Sch=led2_g
set_property -dict { PACKAGE_PIN J4    IOSTANDARD LVCMOS33 } [get_ports { o_led[6] }]; #IO_L21P_T3_DQS_35 Sch=led1_g
set_property -dict { PACKAGE_PIN F6    IOSTANDARD LVCMOS33 } [get_ports { o_led[7] }]; #IO_L19N_T3_VREF_35 Sch=led0_g

## VGA - Pmod JB and Pmod JC
#   Pmod JB
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {o_vga_red[0]}]; 
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports {o_vga_red[1]}];
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {o_vga_red[2]}];
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {o_vga_red[3]}];
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {o_vga_blue[0]}]; 
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {o_vga_blue[1]}];
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {o_vga_blue[2]}];
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {o_vga_blue[3]}];
#   Pmod JC
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {o_vga_green[0]}]; 
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {o_vga_green[1]}];
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports {o_vga_green[2]}];
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {o_vga_green[3]}];
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {o_vga_hs}];
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {o_vga_vs}];

## ChipKit Board Connections
#   SPI Connections
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { i_spi_ss_n }]; #IO_L18N_T2_A11_D27_14 Sch=ck_io[10]
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { i_spi_mosi }]; #IO_L17N_T2_A13_D29_14 Sch=ck_io[11]
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { o_spi_miso }]; #IO_L12N_T1_MRCC_14 Sch=ck_io[12]
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { i_spi_clk  }]; #IO_L12P_T1_MRCC_14 Sch=ck_io[13]
#set_property -dict { PACKAGE_PIN G1    IOSTANDARD LVCMOS33 } [get_ports { o_spi_miso }];
#set_property -dict { PACKAGE_PIN H1    IOSTANDARD LVCMOS33 } [get_ports { i_spi_mosi }];
#set_property -dict { PACKAGE_PIN F1    IOSTANDARD LVCMOS33 } [get_ports { i_spi_clk }];
#set_property -dict { PACKAGE_PIN C1    IOSTANDARD LVCMOS33 } [get_ports { i_spi_ss_n }];

