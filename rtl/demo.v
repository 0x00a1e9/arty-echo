`timescale 1ns/100ps


module TESTBENCH
#(
    parameter CLK_PERIOD_h    = 5,
    parameter [ 2:0] RDY      = 3'b001,
    parameter [ 2:0] LOAD1    = 3'b010,
    parameter [ 2:0] LOAD2    = 3'b011,
    parameter [ 2:0] RECV     = 3'b100,
    parameter [13:0] TMR_MAX  = 14'b10100010110000, // 10416 = round(100MHz/9600Hz) - 1
    parameter [ 2:0] IDX1_MAX = 3'd5,
    parameter [ 3:0] IDX2_MAX = 4'd10
);

// DEMO
reg  CLK = 1'b0;
reg  btn_0;
wire UART_TX;
reg  UART_RX = 1'b1;

// TESTBENCH
reg         tb_send;
reg  [ 2:0] tb_state;
reg  [ 7:0] tb_str [ 4:0];
reg  [ 9:0] tb_data;
reg  [13:0] tb_tmr;
reg  [ 2:0] idx1;
reg  [ 3:0] idx2;
wire        bit_done;
wire        byte_done;
wire        str_done;

DEMO demo (
    CLK,
    btn_0,
    UART_TX,
    UART_RX
);

initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, TESTBENCH);

    CLK       = 1'b0;
    btn_0     = 1'b0;
    UART_RX = 1'b1;

    tb_state  = RDY;
    tb_send   = 1'b1;
    tb_str[0] = 8'h02;
    tb_str[1] = 8'h54;
    tb_str[2] = 8'h33;
    tb_str[3] = 8'h35;
    tb_str[4] = 8'h03;
    tb_data   = 10'd0;
    tb_tmr    = 14'd0;
    idx1      = 3'd0;
    idx2      = 4'd0;

    repeat (2) begin
        #CLK_PERIOD_h CLK = ~CLK;
    end

        #CLK_PERIOD_h tb_send = 1'b0;

    repeat (10000000) begin : gen_clk
        #CLK_PERIOD_h CLK = ~CLK;
    end
end

always @(posedge CLK) begin : state_transition
    case (tb_state)
        RDY:
            if (tb_send)
                tb_state <= LOAD1;
        LOAD1:
            tb_state <= LOAD2;
        LOAD2:
            tb_state <= RECV;
        RECV:
            if (bit_done) begin
                if (byte_done) begin
                    if (str_done)
                        tb_state <= RDY;
                    else
                        tb_state <= LOAD1;
                end
                else begin
                    tb_state <= LOAD2;
                end
            end
    endcase
end

assign bit_done  = (tb_tmr == TMR_MAX)? 1 : 0;
assign byte_done = (idx2 == IDX2_MAX)? 1 : 0;
assign str_done  = (idx1 == IDX1_MAX)? 1 : 0;

always @(posedge CLK) begin : timer
    if (tb_state == RDY) begin
        tb_tmr <= 14'd0;
    end
    else begin
        if (bit_done)
            tb_tmr <= 14'd0;
        else
            tb_tmr <= tb_tmr + 1;
    end
end

always @(posedge CLK) begin : data_latch
    if (tb_state == LOAD1)
        tb_data <= {1'b1, tb_str[idx1], 1'b0};
end

always @(posedge CLK) begin : idx
    case (tb_state)
        RDY: begin
            idx1 <= 3'd0;
            idx2 <= 4'd0;
        end
        LOAD1: begin
            idx1 <= idx1 + 1;
            idx2 <= 4'd0;
        end
        LOAD2: begin
            idx2 <= idx2 + 1;
        end
    endcase
end

always @(posedge CLK) begin : bit0
    case (tb_state)
        RDY: UART_RX <= 1'b1;
        LOAD2: UART_RX <= tb_data[idx2];
    endcase
end

endmodule


module DEMO
#(
    parameter [ 2:0] WAIT_ACTI      = 3'b001,
    parameter [ 2:0] SEND_CHAR      = 3'b011,
    parameter [ 2:0] RDY            = 3'b100,
    parameter [ 2:0] WAIT_RDY       = 3'b101,
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

reg  [ 2:0] demo_state;
reg  [ 7:0] btn_str        [ 7:0];
reg  [ 3:0] str_idx;
reg         send_char;
reg         btn_or_parrot;
reg  [ 7:0] char_to_parrot;

// UART_TX_CTRL
wire        send;
reg  [ 7:0] send_data;
wire        ready;

assign send = send_char;

// UART_RX_CTRL
wire [ 7:0] recv_data;
wire vald_data;

initial begin : asynchronous_reset
    demo_state     <= WAIT_ACTI;

    btn_str[0]     <= 8'h02; // STX
    btn_str[1]     <= 8'h41; // A
    btn_str[2]     <= 8'h52; // R
    btn_str[3]     <= 8'h54; // T
    btn_str[4]     <= 8'h59; // Y
    btn_str[5]     <= 8'h0D; // CR
    btn_str[6]     <= 8'h0A; // LF
    btn_str[7]     <= 8'h03; // ETX

    char_to_parrot <= 8'd0;

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

always @(posedge CLK) begin : state_transition
    case (demo_state)
        WAIT_ACTI:
            if (btn_0 == 1'b1 ^ vald_data == 1'b1) begin
                demo_state <= SEND_CHAR;
                if (btn_0 == 1'b1)
                    btn_or_parrot <= BTN;
                else if (vald_data == 1'b1)
                    btn_or_parrot <= PARROT;
            end
        SEND_CHAR:
            demo_state <= RDY;
        RDY:
            demo_state <= WAIT_RDY;
        WAIT_RDY:
            if (ready == 1'b1) begin
                case (btn_or_parrot)
                    BTN: begin
                        if (str_idx == BTN_STR_LEN)
                            demo_state <= WAIT_ACTI;
                        else
                            demo_state <= SEND_CHAR;
                    end
                    PARROT:
                        demo_state <= WAIT_ACTI;
                endcase
            end
        default: // should never be reached
            demo_state <= WAIT_ACTI;
    endcase
end

always @(posedge CLK) begin : inc_idx
    if (demo_state == WAIT_ACTI)
        str_idx <= 0;
    else if (demo_state == SEND_CHAR)
        str_idx <= str_idx + 1;
end

always @(posedge CLK) begin : char_load
    if (demo_state == SEND_CHAR) begin
        send_char <= 1'b1;
        case (btn_or_parrot)
            BTN:
                send_data <= btn_str[str_idx];
            PARROT:
                send_data <= char_to_parrot;
        endcase
    end
    else begin
        send_char <= 1'b0;
    end
end

// echo back
always @(posedge CLK) begin : parrot_recv_char
    if (vald_data == 1'b1)
        char_to_parrot <= recv_data;
end

endmodule
