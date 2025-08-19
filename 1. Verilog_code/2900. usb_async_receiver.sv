module usb_async_receiver(
    input wire dm,
    input wire dp,
    input wire fast_clk,
    input wire reset,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);
    reg [1:0] state, next_state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    
    localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
    
    // Asynchronous next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (dp && !dm) next_state = SYNC;
            SYNC: if (bit_count == 3'h7) next_state = DATA;
            DATA: if (bit_count == 3'h7) next_state = EOP;
            EOP: if (!dp && !dm) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // Sequential logic
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'h0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            state <= next_state;
            case (state)
                SYNC: bit_count <= bit_count + 1'b1;
                DATA: begin
                    bit_count <= bit_count + 1'b1;
                    shift_reg <= {dp, shift_reg[7:1]};
                    if (bit_count == 3'h7) rx_data <= shift_reg;
                end
                EOP: begin
                    rx_valid <= 1'b1;
                    bit_count <= 3'h0;
                end
                default: begin
                    rx_valid <= 1'b0;
                    bit_count <= 3'h0;
                end
            endcase
        end
    end
endmodule