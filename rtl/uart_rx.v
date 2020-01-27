module UART_RX_CTRL
#(
    parameter [ 2:0] WAIT_START  = 3'b001,
    parameter [ 2:0] STORE_START = 3'b010,
    parameter [ 2:0] STORE_DATA  = 3'b011,
    parameter [ 2:0] STORE_STOP  = 3'b100,
    parameter [ 2:0] STORE_LAST  = 3'b101
)(
    input  wire        CLK,
    input  wire        UART_RX,
    output reg  [ 7:0] recv_data,
    output wire        vald_data
);

reg [ 2:0] rx_reg;
reg        rx_state;
reg [13:0] rx_tmr;

initial begin
    rx_reg   = 3'd0;
    rx_state = WAIT_START;
    rx_tm    = 14'd0
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
                            demo_state,
                            rx_reg[2],
                            rx_reg[1]
                        );

always @(posedge CLK) begin : state_transition
    case (rx_state)
        WAIT_START:
            if (startbit_detected == 1'b1) begin
                rx_state <= STORE_START
                // bit_count?
            end
        STORE_START:
            if ()
                if (rx_reg[1] == 1'b0)
                    rx_state <= STORE_DATA;
                else
                    rx_state <= 

        STORE_DATA:
        STORE_STOP:
        STORE_LAST:
            demo_state <= WAIT_START;
        default: // should never be reached
    endcase
end


endmodule
