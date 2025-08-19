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
    // State definitions
    localparam IDLE = 2'b00, SYNC = 2'b01, DATA = 2'b10, EOP = 2'b11;
    
    // State registers
    reg [1:0] state, next_state;
    reg [2:0] bit_count, next_bit_count;
    reg [7:0] shift_reg, next_shift_reg;
    reg next_rx_valid;
    reg next_rx_error;
    reg [7:0] next_rx_data;
    
    // Pre-compute common conditions to reduce logic depth
    wire is_bit_7 = (bit_count == 3'h7);
    wire is_idle_to_sync = (state == IDLE) && dp && !dm;
    wire is_eop_condition = (state == EOP) && !dp && !dm;
    
    // Bit count logic separated for path balancing
    always @(*) begin
        case (state)
            IDLE:   next_bit_count = 3'h0;
            SYNC:   next_bit_count = bit_count + 1'b1;
            DATA:   next_bit_count = bit_count + 1'b1;
            EOP:    next_bit_count = 3'h0;
            default: next_bit_count = 3'h0;
        endcase
    end
    
    // State transition logic
    always @(*) begin
        case (state)
            IDLE:   next_state = is_idle_to_sync ? SYNC : IDLE;
            SYNC:   next_state = is_bit_7 ? DATA : SYNC;
            DATA:   next_state = is_bit_7 ? EOP : DATA;
            EOP:    next_state = is_eop_condition ? IDLE : EOP;
            default: next_state = IDLE;
        endcase
    end
    
    // Data path logic
    always @(*) begin
        // Default assignments
        next_shift_reg = shift_reg;
        next_rx_data = rx_data;
        next_rx_valid = 1'b0;
        next_rx_error = rx_error;
        
        // Specific state behaviors
        if (state == DATA) begin
            next_shift_reg = {dp, shift_reg[7:1]};
            if (is_bit_7) begin
                next_rx_data = {dp, shift_reg[7:1]};
            end
        end
        
        if (state == EOP) begin
            next_rx_valid = 1'b1;
        end
    end
    
    // Sequential logic
    always @(posedge fast_clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 3'h0;
            shift_reg <= 8'h0;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;
            rx_data <= 8'h0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            shift_reg <= next_shift_reg;
            rx_valid <= next_rx_valid;
            rx_error <= next_rx_error;
            rx_data <= next_rx_data;
        end
    end
endmodule