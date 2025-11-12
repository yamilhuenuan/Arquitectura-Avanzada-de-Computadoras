##==========================================================
## Clock 100 MHz de la placa
##==========================================================
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports { clk }];

##==========================================================
## Botón de reset (BTNU) -> rst_n (activo en bajo en tu lógica)
##==========================================================
set_property -dict { PACKAGE_PIN M18 IOSTANDARD LVCMOS33 } [get_ports { btn_reset }];
# IO_L4N_T0_D05_14 Sch=btnu
# En tu lógica interna tratá rst_n como "1 = normal, 0 = reset"

##==========================================================
## USB-UART integrado (conector micro-USB J6)
## C4: TX desde FPGA hacia FTDI (PC ve esto como RX)
## D4: RX desde FTDI hacia FPGA
##==========================================================
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports { uart_rx }];
# IO_L7P_T1_AD6P_35 Sch=uart_txd_in  (FPGA -> PC)

set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports { uart_tx }];
# IO_L11N_T1_SRCC_35 Sch=uart_rxd_out (PC -> FPGA)

##==========================================================
## LEDs de usuario LD0..LD7 -> leds[7:0]
##==========================================================
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { leds[0] }]; # LD0
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { leds[1] }]; # LD1
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { leds[2] }]; # LD2
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { leds[3] }]; # LD3
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { leds[4] }]; # LD4
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { leds[5] }]; # LD5
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { leds[6] }]; # LD6
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { leds[7] }]; # LD7
