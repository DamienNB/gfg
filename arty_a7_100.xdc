## Arty Board Constraints

## Clock
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS33} [get_ports {i_clk}];
create_clock -add -name sys_clk_pin -period 10.00 \
    -waveform {0 5} [get_ports {i_clk}];

## Buttons
set_property -dict {PACKAGE_PIN C2  IOSTANDARD LVCMOS33} [get_ports {i_arst_n}];

## Switches  
#set_property -dict {PACKAGE_PIN A8  IOSTANDARD LVCMOS33} [get_ports {i_sw[0]}];
#set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {i_sw[1]}];
#set_property -dict {PACKAGE_PIN C10 IOSTANDARD LVCMOS33} [get_ports {i_sw[2]}];
#set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {i_sw[3]}];

## LEDs
set_property -dict {PACKAGE_PIN H5  IOSTANDARD LVCMOS33} [get_ports {o_led[0]}]; 
set_property -dict {PACKAGE_PIN J5  IOSTANDARD LVCMOS33} [get_ports {o_led[1]}];
set_property -dict {PACKAGE_PIN T9  IOSTANDARD LVCMOS33} [get_ports {o_led[2]}];
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {o_led[3]}];

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
