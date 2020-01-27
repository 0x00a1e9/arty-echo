module UART_RX_CTRL
#(
    parameter [ 2:0] WAIT_START  = 3'b001,
    parameter [ 2:0] STORE_START = 3'b010,
    parameter [ 2:0] STORE_DATA  = 3'b011,
    parameter [ 2:0] STORE_STOP  = 3'b100,
    parameter [ 2:0] STORE_LAST  = 3'b101,
    parameter [13:0] TMR_MAX     = 14'b10100010110000 // 10416 = round(100MHz/9600Hz) - 1
)(
    input  wire        CLK,
    input  wire        UART_RX,
    output reg  [ 7:0] recv_data,
    output wire        vald_data
);

reg  [ 2:0] rx_reg    = 3'd0;
reg  [ 2:0] rx_state  = WAIT_START;
reg  [13:0] rx_tmr    = 14'd0;
reg  [ 2:0] bit_count = 3'd0;
wire        sample_point;

initial begin
    rx_reg    = 3'd0;
    rx_state  = WAIT_START;
    rx_tmr    = 14'd0;
    bit_count = 3'd0;
end

always @(posedge CLK) begin : rx_latch_n_shift
    rx_reg <= {rx_reg[1:0], UART_RX};
end

function set_startbit_detected;
    input state, rx2, rx1;
    begin
        if (state==WAIT_START && rx2==1'b1 && rx1==1'b0)
            set_startbit_detected = 1'b1;
        else
            set_startbit_detected = 1'b0;
    end
endfunction

assign startbit_detected = set_startbit_detected(
                            rx_state,
                            rx_reg[2],
                            rx_reg[1]
                        );

always @(posedge CLK) begin : rx_timer
    if (startbit_detected == 1'b1) begin
        rx_tmr <= 14'd0;
    end
    else begin
        if (rx_tmr == TMR_MAX)
            rx_tmr <= 14'd0;
        else
            rx_tmr <= rx_tmr + 14'd1;
    end
end

assign sample_point = (rx_tmr == 14'd0)? 1'b1 : 1'b0;

always @(posedge CLK) begin : state_transition_n_bit_count
    case (rx_state)
        WAIT_START:
            if (startbit_detected == 1'b1) begin
                rx_state <= STORE_START;
                bit_count <= 3'd0;
            end
        STORE_START:
            if (sample_point == 1'b1) begin
                if (rx_reg[1] == 1'b0)
                    rx_state <= STORE_DATA;
                else // metastability?
                    rx_state <= WAIT_START;
            end
        STORE_DATA:
            if (sample_point == 1'b1) begin
                recv_data <= {rx_reg[1], recv_data[7:1]};
                if (bit_count == 3'd7)
                    rx_state <= STORE_STOP;
                else
                    bit_count <= bit_count + 3'd1;
            end
        STORE_STOP:
            if (sample_point == 1'b1) begin
                if (rx_reg[1] == 1'b1)
                    rx_state <= STORE_LAST;
                else // error?
                    rx_state <= WAIT_START;
            end
        STORE_LAST:
            rx_state <= WAIT_START;
        default: // should never be reached
            rx_state <= WAIT_START;
    endcase
end

assign vald_data = (rx_state == STORE_LAST)? 1'b1 : 1'b0;

endmodule
