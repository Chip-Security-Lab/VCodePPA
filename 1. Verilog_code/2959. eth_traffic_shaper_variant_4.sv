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
    
    // Pre-compute next token count logic to reduce critical path
    reg [15:0] next_token_count;
    reg [15:0] next_packet_byte_count;
    reg next_packet_in_progress;
    reg next_packet_throttled;
    reg next_tokens_available;
    reg [DATA_WIDTH-1:0] next_data_out;
    reg next_data_valid_out;
    
    // Skip-carry adder for token_count increment
    wire [15:0] token_inc_sum;
    skip_carry_adder #(
        .WIDTH(16)
    ) token_adder (
        .a(token_count),
        .b(TOKEN_INC_PER_CYCLE),
        .cin(1'b0),
        .sum(token_inc_sum)
    );
    
    // Skip-carry adder for packet_byte_count increment
    wire [15:0] byte_inc_sum;
    skip_carry_adder #(
        .WIDTH(16)
    ) byte_adder (
        .a(packet_byte_count),
        .b(16'b0),
        .cin(1'b1),  // Adding 1
        .sum(byte_inc_sum)
    );
    
    // Token bucket calculation
    always @(*) begin
        if (token_count < TOKEN_MAX && TOKEN_INC_PER_CYCLE > 0) begin
            next_token_count = (token_inc_sum > TOKEN_MAX) ? TOKEN_MAX : token_inc_sum;
        end else begin
            next_token_count = token_count;
        end
        
        // Apply token consumption if needed
        if (data_valid_in && packet_in_progress && !packet_throttled && 
            enable_shaping && next_token_count > 0 && packet_byte_count < packet_byte_limit) begin
            next_token_count = next_token_count - 1'b1;
        end
        
        next_tokens_available = (next_token_count > 0);
    end
    
    // Packet tracking logic
    always @(*) begin
        if (packet_start) begin
            next_packet_in_progress = 1'b1;
            next_packet_byte_count = 16'd0;
            next_packet_throttled = 1'b0;
        end else if (packet_end) begin
            next_packet_in_progress = 1'b0;
            next_packet_byte_count = packet_byte_count;
            next_packet_throttled = packet_throttled;
        end else begin
            next_packet_in_progress = packet_in_progress;
            next_packet_byte_count = packet_byte_count;
            next_packet_throttled = packet_throttled;
        end
        
        // Update byte count if forwarding data
        if (data_valid_in && packet_in_progress && !packet_throttled) begin
            if (enable_shaping) begin
                if (next_token_count > 0 && packet_byte_count < packet_byte_limit) begin
                    next_packet_byte_count = byte_inc_sum;
                end
            end else begin
                next_packet_byte_count = byte_inc_sum;
            end
            
            next_packet_throttled = (enable_shaping && packet_byte_count >= packet_byte_limit);
        end
    end
    
    // Data forwarding logic
    always @(*) begin
        next_data_out = data_in;
        
        if (data_valid_in && packet_in_progress && !packet_throttled) begin
            if (enable_shaping) begin
                // Check token bucket and packet byte limit
                if (next_token_count > 0 && packet_byte_count < packet_byte_limit) begin
                    next_data_valid_out = 1'b1;
                end else begin
                    next_data_valid_out = 1'b0;
                end
            end else begin
                // Pass-through mode when shaping disabled
                next_data_valid_out = data_valid_in;
            end
        end else begin
            next_data_valid_out = 1'b0;
        end
    end
    
    // Sequential logic with retimed registers
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
            // Register updates with pre-computed values
            data_out <= next_data_out;
            data_valid_out <= next_data_valid_out;
            token_count <= next_token_count;
            tokens_available <= next_tokens_available;
            packet_byte_count <= next_packet_byte_count;
            packet_in_progress <= next_packet_in_progress;
            packet_throttled <= next_packet_throttled;
        end
    end
endmodule

module skip_carry_adder #(
    parameter WIDTH = 16
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum
);
    wire [WIDTH-1:0] prop, gen;
    wire [WIDTH:0] carry;
    
    // Generate propagate and generate signals
    assign prop = a;
    assign gen = b;
    assign carry[0] = cin;
    
    // Skip-carry adder implementation
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 4) begin : SKIP_BLOCKS
            // Generate group propagate and generate signals
            wire block_p, block_g;
            
            if (i+3 < WIDTH) begin
                assign block_p = prop[i] & prop[i+1] & prop[i+2] & prop[i+3];
                assign block_g = gen[i+3] | 
                                (prop[i+3] & gen[i+2]) |
                                (prop[i+3] & prop[i+2] & gen[i+1]) |
                                (prop[i+3] & prop[i+2] & prop[i+1] & gen[i]);
                assign carry[i+4] = block_g | (block_p & carry[i]);
            end
            
            // Generate individual bit carries
            if (i < WIDTH) assign carry[i+1] = gen[i] | (prop[i] & carry[i]);
            if (i+1 < WIDTH) assign carry[i+2] = gen[i+1] | (prop[i+1] & carry[i+1]);
            if (i+2 < WIDTH) assign carry[i+3] = gen[i+2] | (prop[i+2] & carry[i+2]);
        end
    endgenerate
    
    // Calculate sum bits
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : SUM_BITS
            assign sum[i] = a[i] ^ b[i] ^ carry[i];
        end
    endgenerate
endmodule