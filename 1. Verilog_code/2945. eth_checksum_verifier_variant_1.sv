//SystemVerilog - IEEE 1364-2005
module eth_checksum_verifier (
    input wire clock,
    input wire reset,
    input wire data_valid,
    input wire [7:0] rx_byte,
    input wire packet_start,
    input wire packet_end,
    output reg checksum_ok,
    output reg checksum_valid
);
    // State encoding optimized for one-hot encoding with clear naming
    localparam [4:0] STATE_IDLE     = 5'b00001, 
                     STATE_HEADER   = 5'b00010, 
                     STATE_DATA     = 5'b00100, 
                     STATE_CSUM_LOW = 5'b01000, 
                     STATE_CSUM_HIGH = 5'b10000;
    
    // Control path registers
    reg [4:0] current_state;
    reg [4:0] next_state;
    reg [9:0] byte_counter;
    reg [9:0] next_byte_counter;
    
    // Data path registers - separated for better timing
    reg [15:0] checksum_accumulator;
    reg [15:0] next_checksum_accumulator;
    reg [7:0]  checksum_byte_low;
    reg [7:0]  next_checksum_byte_low;
    reg [15:0] received_checksum;
    
    // Pipeline registers for output generation
    reg checksum_comparison_valid;
    reg checksum_comparison_result;
    
    // Control path - state transition logic
    always @(*) begin
        // Default assignments
        next_state = current_state;
        next_byte_counter = byte_counter;
        
        case (current_state)
            STATE_IDLE: begin
                if (packet_start)
                    next_state = STATE_HEADER;
            end
            
            STATE_HEADER: begin
                if (data_valid) begin
                    next_byte_counter = byte_counter + 10'd1;
                    if (byte_counter == 10'd12)
                        next_state = STATE_DATA;
                end
                
                if (packet_end)
                    next_state = STATE_IDLE;
            end
            
            STATE_DATA: begin
                if (data_valid && packet_end)
                    next_state = STATE_CSUM_LOW;
                else if (packet_end)
                    next_state = STATE_IDLE;
            end
            
            STATE_CSUM_LOW: begin
                if (data_valid)
                    next_state = STATE_CSUM_HIGH;
                if (packet_end)
                    next_state = STATE_IDLE;
            end
            
            STATE_CSUM_HIGH: begin
                if (data_valid)
                    next_state = STATE_IDLE;
            end
            
            default: next_state = STATE_IDLE;
        endcase
        
        // Priority reset on packet_start
        if (packet_start) begin
            next_state = STATE_HEADER;
            next_byte_counter = 10'd0;
        end
    end
    
    // Data path - checksum calculation logic
    always @(*) begin
        // Default assignments
        next_checksum_accumulator = checksum_accumulator;
        next_checksum_byte_low = checksum_byte_low;
        
        case (current_state)
            STATE_IDLE: begin
                next_checksum_accumulator = 16'd0;
            end
            
            STATE_DATA: begin
                if (data_valid)
                    next_checksum_accumulator = checksum_accumulator + {8'h0, rx_byte};
            end
            
            STATE_CSUM_LOW: begin
                if (data_valid)
                    next_checksum_byte_low = rx_byte;
            end
            
            default: begin
                // Maintain current values
            end
        endcase
        
        // Reset accumulator on packet start
        if (packet_start)
            next_checksum_accumulator = 16'd0;
    end
    
    // Registered state update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_state <= STATE_IDLE;
            byte_counter <= 10'd0;
            checksum_accumulator <= 16'd0;
            checksum_byte_low <= 8'h0;
            received_checksum <= 16'd0;
            checksum_comparison_valid <= 1'b0;
            checksum_comparison_result <= 1'b0;
        end else begin
            current_state <= next_state;
            byte_counter <= next_byte_counter;
            checksum_accumulator <= next_checksum_accumulator;
            checksum_byte_low <= next_checksum_byte_low;
            
            // Capture received checksum
            if (current_state == STATE_CSUM_HIGH && data_valid)
                received_checksum <= {rx_byte, checksum_byte_low};
                
            // Generate comparison result with pipelining
            if (current_state == STATE_CSUM_HIGH && data_valid) begin
                checksum_comparison_valid <= 1'b1;
                checksum_comparison_result <= (checksum_accumulator == {rx_byte, checksum_byte_low});
            end else if (current_state == STATE_IDLE && packet_start) begin
                checksum_comparison_valid <= 1'b0;
                checksum_comparison_result <= 1'b0;
            end
        end
    end
    
    // Output registers with pipelined timing
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            checksum_valid <= 1'b0;
            checksum_ok <= 1'b0;
        end else begin
            checksum_valid <= checksum_comparison_valid;
            checksum_ok <= checksum_comparison_result;
        end
    end
endmodule