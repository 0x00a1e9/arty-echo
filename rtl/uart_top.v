module UART
#(
    parameter [ 2:0] WAIT_ACTI      = 3'b001,
    parameter [ 2:0] SEND_CHAR      = 3'b010,
    parameter [ 2:0] RDY            = 3'b011,
    parameter [ 2:0] WAIT_RDY       = 3'b100,
    parameter [ 3:0] BTN_STR_LEN    = 4'd8,
    parameter [ 1:0] PARROT_STR_LEN = 2'd3,
    parameter        BTN            = 1'b0,
    parameter        PARROT         = 1'b1
)
(
    input  wire CLK,       // E3
    input  wire btn_0,     // D9
    output wire UART_TX,   // D10
    input  wire UART_RX    // A9
);

reg  [ 2:0] uart_state;
reg  [ 7:0] btn_str        [ 7:0];
reg  [ 3:0] str_idx;
reg         send_mode;
reg         send_char;

// UART_TX_CTRL
wire        send;
reg  [ 7:0] send_data;
wire        ready;

assign send = send_char;

// UART_RX_CTRL
wire [ 7:0] recv_data;
wire        vald_data;

// FIFO
wire        w_enable;
wire        r_enable;
wire [ 7:0] r_data;
wire [ 8:0] count;


initial begin : asynchronous_reset
    uart_state     <= WAIT_ACTI;

    btn_str[0]     <= 8'h02; // STX
    btn_str[1]     <= 8'h41; // A
    btn_str[2]     <= 8'h52; // R
    btn_str[3]     <= 8'h54; // T
    btn_str[4]     <= 8'h59; // Y
    btn_str[5]     <= 8'h0D; // CR
    btn_str[6]     <= 8'h0A; // LF
    btn_str[7]     <= 8'h03; // ETX

    send_char      <= 1'b0;
    send_data      <= 0;
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

assign w_enable = (vald_data == 1'b1 && count < 2**8);
assign r_enable = (count > 0 && uart_state == WAIT_ACTI)? 1 : 0;

FIFO fifo (
    CLK,
    w_enable,
    r_enable,
    recv_data, // w_data
    r_data,
    count
);

always @(posedge CLK) begin : state_transition
    case (uart_state)
        WAIT_ACTI:
            if (r_enable) begin
                uart_state <= SEND_CHAR;
                send_mode  <= PARROT;
            end
            else if (btn_0 == 1'b1) begin
                uart_state <= SEND_CHAR;
                send_mode  <= BTN;
            end
        SEND_CHAR:
            uart_state <= RDY;
        RDY:
            uart_state <= WAIT_RDY;
        WAIT_RDY:
            if (ready == 1'b1) begin
                case (send_mode)
                    PARROT: begin
                        uart_state <= WAIT_ACTI;
                    end
                    BTN: begin
                        if (str_idx == BTN_STR_LEN)
                            uart_state <= WAIT_ACTI;
                        else
                            uart_state <= SEND_CHAR;
                    end
                endcase
            end
        default: // should never be reached
            uart_state <= WAIT_ACTI;
    endcase
end

always @(posedge CLK) begin : inc_idx
    if (uart_state == WAIT_ACTI)
        str_idx <= 0;
    else if (uart_state == SEND_CHAR)
        str_idx <= str_idx + 1;
end

always @(posedge CLK) begin : char_load
    if (uart_state == SEND_CHAR) begin
        send_char <= 1'b1;
        if (send_mode == PARROT)
            send_data <= r_data;
        else if (send_mode == BTN)
            send_data <= btn_str[str_idx];
    end
    else begin
        send_char <= 1'b0;
    end
end

endmodule
