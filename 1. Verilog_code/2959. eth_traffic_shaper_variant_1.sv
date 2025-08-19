//SystemVerilog
module eth_traffic_shaper #(
    parameter DATA_WIDTH = 8,
    parameter RATE_LIMIT = 100,  // Units: Mbps
    parameter TOKEN_MAX = 1500   // Maximum burst size in bytes
) (
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire data_valid_in,
    input wire packet_start,
    input wire packet_end,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid_out,
    output reg tokens_available,
    output reg [15:0] token_count,
    input wire [15:0] packet_byte_limit, // Per-packet byte limit
    input wire enable_shaping
);
    localparam TOKEN_INC_PER_CYCLE = RATE_LIMIT / 8; // Bytes per cycle
    
    reg [15:0] packet_byte_count;
    reg packet_in_progress;
    reg packet_throttled;
    
    // Token refill logic
    wire [15:0] new_token_count;
    wire [15:0] tokens_to_add;
    
    // Optimize comparisons with range checks
    wire token_refill_needed = (token_count < TOKEN_MAX);
    wire token_increment_valid = (TOKEN_INC_PER_CYCLE > 0);
    wire would_exceed_max = (token_count + TOKEN_INC_PER_CYCLE > TOKEN_MAX);
    
    // Optimize with efficient calculations
    assign tokens_to_add = token_increment_valid ? TOKEN_INC_PER_CYCLE : 16'd0;
    assign new_token_count = would_exceed_max ? TOKEN_MAX : (token_count + tokens_to_add);
    
    // Packet forwarding conditions
    wire can_forward_data = data_valid_in && packet_in_progress && !packet_throttled;
    wire has_tokens = (token_count > 0);
    wire within_packet_limit = (packet_byte_count < packet_byte_limit);
    wire shaping_allows_forwarding = !enable_shaping || (has_tokens && within_packet_limit);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            data_valid_out <= 1'b0;
            token_count <= TOKEN_MAX;
            tokens_available <= 1'b1;
            packet_byte_count <= 16'd0;
            packet_in_progress <= 1'b0;
            packet_throttled <= 1'b0;
        end else begin
            // Token bucket refill - optimized to reduce comparator chain
            if (token_refill_needed) begin
                token_count <= new_token_count;
            end
            
            // Token availability status - direct assignment
            tokens_available <= has_tokens;
            
            // Packet tracking - prioritized handling
            if (packet_start) begin
                packet_in_progress <= 1'b1;
                packet_byte_count <= 16'd0;
                packet_throttled <= 1'b0;
            end else if (packet_end) begin
                packet_in_progress <= 1'b0;
            end
            
            // Default data_valid_out 
            data_valid_out <= 1'b0;
            
            // Data forwarding with traffic shaping - optimized conditional structure
            if (can_forward_data) begin
                if (enable_shaping) begin
                    if (has_tokens && within_packet_limit) begin
                        data_out <= data_in;
                        data_valid_out <= 1'b1;
                        token_count <= token_count - 1'b1;
                        packet_byte_count <= packet_byte_count + 1'b1;
                    end else begin
                        packet_throttled <= (packet_byte_count >= packet_byte_limit);
                    end
                end else begin
                    // Pass-through mode when shaping disabled
                    data_out <= data_in;
                    data_valid_out <= 1'b1;
                    packet_byte_count <= packet_byte_count + 1'b1;
                end
            end
        end
    end
    
    // IEEE 1364-2005 Verilog standard
endmodule