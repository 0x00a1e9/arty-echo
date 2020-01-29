create_clock -period 10.000 -name CLK -waveform {0.000 5.000} -add [get_ports CLK]

set_property IOSTANDARD LVCMOS33 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports btn_0]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]

set_property PACKAGE_PIN E3 [get_ports CLK]
set_property PACKAGE_PIN D9 [get_ports btn_0]
set_property PACKAGE_PIN D10 [get_ports UART_TX]
set_property PACKAGE_PIN A9 [get_ports UART_RX]
