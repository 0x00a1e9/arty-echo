module UART_TX_CTRL
#(
    parameter [ 1:0] RDY       = 2'b01,
    parameter [ 1:0] LOAD      = 2'b10,
    parameter [ 1:0] SEND      = 2'b11,
    parameter        INDEX_MAX = 0,
    parameter [13:0] TIMER_MAX = 14'b10100010110000 // 10416 = round(100MHz/9600Hz) - 1
)
(
    input  wire       CLK,
    input  wire       send,
    input  wire [7:0] send_data,
    output wire       ready,
    output wire       UART_TX
);

reg         tx_bit    = 1'b1;
reg  [ 1:0] tx_state  = RDY;
reg  [10:0] tx_data;
reg         index     = 0;
reg  [13:0] tx_tmr    = 14'b00000000000000;
wire        load_done;

always @(posedge CLK) begin : state_transition
    case (tx_state)
        RDY:
            if (send) begin
                tx_state <= LOAD;
            end
        LOAD:
            tx_state <= SEND;
        SEND:
            if (load_done) begin
                if (index == INDEX_MAX) begin
                    tx_state <= RDY;
                end
                else begin
                    tx_state <= LOAD;
                end
            end
        default: // should never be reached
            tx_state <= RDY;
    endcase
end

always @(posedge CLK) begin : timing
    if (tx_state == RDY) begin
        tx_tmr <= 14'b00000000000000;
    end
    else begin
        if (load_done) begin
            tx_tmr <= 14'b00000000000000;
        end
        else begin
            tx_tmr <= tx_tmr + 1;
        end
    end
end

always @(posedge CLK) begin : increment_index
    if (tx_state == RDY) begin
        index <= 0;
    end
    else if (tx_state == LOAD) begin
        index <= index + 1;
    end
end

always @(posedge CLK) begin : data_latch
    if (send) begin
        tx_data <= {1'b1, send_data, 1'b0};
    end
end

always @(posedge CLK) begin : bit
    if (tx_state == RDY) begin
        tx_bit <= 1'b1;
    end
    else if (tx_state == LOAD) begin
        tx_bit <= tx_data[index];
    end
end

function set_load_done;
input tmr;
begin
    set_load_done = (tmr == TIMER_MAX)? 1 : 0;
end
endfunction

function set_ready;
input state;
begin
    set_ready = (tx_state == RDY)? 1 : 0;
end
endfunction

assign load_done = set_load_done(tx_tmr);
assign UART_TX   = tx_bit;
assign ready     = set_ready(tx_state);

endmodule
