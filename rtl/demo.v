`timescale 1ns/100ps


module TESTBENCH;

parameter CLK_PERIOD_h = 5;

reg  CLK = 1'b0;
reg  btn_0;
wire UART_TX;

DEMO demo (
    CLK,
    btn_0,
    UART_TX
);

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, TESTBENCH);

    CLK = 1'b0;
    btn_0 = 1'b1;
end

always #CLK_PERIOD_h begin
    CLK = ~CLK;
end

endmodule


module DEMO
#(
    parameter [ 2:0] WAIT_BTN   = 3'b001,
    parameter [ 2:0] SEND_CHAR  = 3'b011,
    parameter [ 2:0] RDY        = 3'b100,
    parameter [ 2:0] WAIT_RDY   = 3'b101,
    parameter [ 3:0] STR_LEN    = 4'b1010
)
(
    input  wire CLK,       // E3
    input  wire btn_0,     // D9
    output wire UART_TX    // D10
);

// UART_TX_CTRL
reg  [ 2:0] demo_state;
reg  [ 7:0] data_arr [ 9:0];
reg  [ 3:0] str_idx;
reg         send_char;

wire        send;
reg  [ 7:0] send_data;
wire        ready;

assign send = send_char;

// UART_RX_CTRL
wire        UART_RX;
wire [ 7:0] recv_data;
wire        vald_data;

assign UART_RX = UART_TX;

initial begin : asynchronous_reset
    demo_state  <= WAIT_BTN;

    data_arr[0] <= 8'h01; // SOH
    data_arr[1] <= 8'h02; // STX
    data_arr[2] <= 8'h41; // A
    data_arr[3] <= 8'h52; // R
    data_arr[4] <= 8'h54; // T
    data_arr[5] <= 8'h59; // Y 
    data_arr[6] <= 8'h0D; // CR
    data_arr[7] <= 8'h0A; // LF
    data_arr[8] <= 8'h03; // ETX
    data_arr[9] <= 8'h04; // EOT

    send_char   <= 1'b0;
    send_data   <= 0;
end

UART_TX_CTRL uart_tx_ctrl (
    CLK,
    send,
    send_data,
    ready,
    UART_TX
);

UART_RX_CTRL uart_rx_ctrl (
    CLK,
    UART_RX,
    recv_data,
    vald_data
);

always @(posedge CLK) begin : state_transition
    case (demo_state)
        WAIT_BTN:
            if (btn_0 == 1'b1)
                demo_state <= SEND_CHAR;
        SEND_CHAR:
            demo_state <= RDY;
        RDY:
            demo_state <= WAIT_RDY;
        WAIT_RDY:
            if (ready == 1'b1) begin
                if (str_idx == STR_LEN)
                    demo_state <= WAIT_BTN;
                else
                    demo_state <= SEND_CHAR;
            end
        default: // should never be reached
            demo_state <= WAIT_BTN;
    endcase
end

always @(posedge CLK) begin : inc_idx
    if (demo_state == WAIT_BTN)
        str_idx <= 0;
    else if (demo_state == SEND_CHAR)
        str_idx <= str_idx + 1;
end

always @(posedge CLK) begin : char_load
    if (demo_state == SEND_CHAR) begin
        send_char <= 1'b1;
        send_data <= data_arr[str_idx];
    end
end

endmodule
