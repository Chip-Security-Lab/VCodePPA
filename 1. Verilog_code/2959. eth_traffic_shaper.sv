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
            // Token bucket refill
            if (token_count < TOKEN_MAX) begin
                if (TOKEN_INC_PER_CYCLE > 0) begin
                    token_count <= (token_count + TOKEN_INC_PER_CYCLE > TOKEN_MAX) ? 
                                  TOKEN_MAX : token_count + TOKEN_INC_PER_CYCLE;
                end
            end
            
            // Token availability status
            tokens_available <= (token_count > 0);
            
            // Packet tracking
            if (packet_start) begin
                packet_in_progress <= 1'b1;
                packet_byte_count <= 16'd0;
                packet_throttled <= 1'b0;
            end else if (packet_end) begin
                packet_in_progress <= 1'b0;
            end
            
            // Data forwarding with traffic shaping
            if (data_valid_in && packet_in_progress && !packet_throttled) begin
                if (enable_shaping) begin
                    // Check token bucket and packet byte limit
                    if (token_count > 0 && packet_byte_count < packet_byte_limit) begin
                        data_out <= data_in;
                        data_valid_out <= 1'b1;
                        token_count <= token_count - 1'b1;
                        packet_byte_count <= packet_byte_count + 1'b1;
                    end else begin
                        data_valid_out <= 1'b0;
                        packet_throttled <= (packet_byte_count >= packet_byte_limit);
                    end
                end else begin
                    // Pass-through mode when shaping disabled
                    data_out <= data_in;
                    data_valid_out <= data_valid_in;
                    packet_byte_count <= packet_byte_count + 1'b1;
                end
            end else begin
                data_valid_out <= 1'b0;
            end
        end
    end
endmodule