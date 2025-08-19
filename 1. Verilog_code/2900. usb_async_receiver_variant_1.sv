//SystemVerilog
module usb_async_receiver(
    input wire dm,
    input wire dp,
    input wire fast_clk,
    input wire reset,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg rx_error
);
    // IEEE 1364-2005 compliant
    reg [1:0] state, next_state;
    reg [2:0] bit_count, next_bit_count;
    reg [7:0] shift_reg, next_shift_reg;
    reg next_rx_valid, next_rx_error, next_rx_data_load;
    
    localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
    
    // Pre-compute common conditions to reduce critical path
    wire bit_count_max = (bit_count == 3'h7);
    wire dp_and_not_dm = dp && !dm;
    wire not_dp_and_not_dm = !dp && !dm;
    
    // Optimized next state logic
    always @(*) begin
        next_state = state; // Default assignment
        next_bit_count = bit_count;
        next_shift_reg = shift_reg;
        next_rx_valid = 1'b0;
        next_rx_error = rx_error;
        next_rx_data_load = 1'b0;
        
        case (state)
            IDLE: begin
                next_bit_count = 3'h0;
                if (dp_and_not_dm) next_state = SYNC;
            end
            
            SYNC: begin
                next_bit_count = bit_count + 1'b1;
                if (bit_count_max) next_state = DATA;
            end
            
            DATA: begin
                next_bit_count = bit_count + 1'b1;
                next_shift_reg = {dp, shift_reg[7:1]};
                if (bit_count_max) begin
                    next_state = EOP;
                    next_rx_data_load = 1'b1;
                end
            end
            
            EOP: begin
                next_bit_count = 3'h0;
                next_rx_valid = 1'b1;
                if (not_dp_and_not_dm) next_state = IDLE;
            end
            
            default: begin
                next_state = IDLE;
                next_bit_count = 3'h0;
            end
        endcase
    end
    
    // Sequential logic with reduced conditional complexity
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'h0;
            shift_reg <= 8'h0;
            rx_data <= 8'h0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
            rx_valid <= next_rx_valid;
            rx_error <= next_rx_error;
            
            if (next_rx_data_load) begin
                rx_data <= next_shift_reg;
            end
        end
    end
endmodule