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

// UART
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

UART uart (
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
