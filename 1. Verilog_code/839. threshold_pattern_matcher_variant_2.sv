//SystemVerilog
module threshold_pattern_matcher #(parameter W = 16, THRESHOLD = 3) (
    input [W-1:0] data, pattern,
    output match_flag
);
    // Count matching bits
    wire [W-1:0] xnor_result = ~(data ^ pattern);
    wire [$clog2(W+1)-1:0] match_count;
    
    // Optimized bit counter implementation
    bit_counter #(.WIDTH(W)) counter (
        .bits_in(xnor_result),
        .count_out(match_count)
    );
    
    assign match_flag = (match_count >= THRESHOLD);
endmodule

module bit_counter #(parameter WIDTH = 16) (
    input [WIDTH-1:0] bits_in,
    output [$clog2(WIDTH+1)-1:0] count_out
);
    // Use barrel shifter based approach for counting
    wire [$clog2(WIDTH+1)-1:0] count;
    
    generate
        if (WIDTH <= 4) begin: small_width
            // For small widths, use direct approach
            assign count = bits_in[0] + bits_in[1] + 
                          ((WIDTH > 2) ? bits_in[2] : 0) + 
                          ((WIDTH > 3) ? bits_in[3] : 0);
        end
        else begin: barrel_shifter_count
            barrel_shifter_bit_counter #(
                .WIDTH(WIDTH)
            ) barrel_counter (
                .bits_in(bits_in),
                .count_out(count)
            );
        end
    endgenerate
    
    assign count_out = count;
endmodule

module barrel_shifter_bit_counter #(parameter WIDTH = 16) (
    input [WIDTH-1:0] bits_in,
    output [$clog2(WIDTH+1)-1:0] count_out
);
    localparam COUNT_WIDTH = $clog2(WIDTH+1);
    
    // Stage outputs
    wire [WIDTH-1:0] stage_out [COUNT_WIDTH:0];
    wire [COUNT_WIDTH-1:0] counts;
    
    // First stage gets the input bits
    assign stage_out[0] = bits_in;
    
    // Barrel shifter implementation
    genvar i, j;
    generate
        for (i = 0; i < COUNT_WIDTH; i = i + 1) begin: barrel_stage
            // Shift distance for this stage is 2^i
            localparam SHIFT = 1 << i;
            
            // Calculate counts for this stage
            wire [WIDTH-1:0] shifted_bits;
            
            // Create barrel shifter stage with correct width
            if (SHIFT < WIDTH) begin: valid_shift
                assign shifted_bits = {{SHIFT{1'b0}}, stage_out[i][WIDTH-1:SHIFT]};
                
                // Count bits for this position
                wire [WIDTH-1:0] stage_sum = stage_out[i] + shifted_bits;
                
                // Output for next stage
                assign stage_out[i+1] = stage_sum;
                
                // Capture the count bit for this significance
                assign counts[i] = stage_out[COUNT_WIDTH][1<<i];
            end
            else begin: invalid_shift
                // For shifts beyond width, just propagate
                assign stage_out[i+1] = stage_out[i];
                assign counts[i] = 1'b0;
            end
        end
    endgenerate
    
    // Construct the output from individual count bits
    // Each bit position represents powers of 2 in the count
    reg [COUNT_WIDTH-1:0] final_count;
    
    always @(*) begin
        final_count = 0;
        for (int k = 0; k < COUNT_WIDTH; k = k + 1) begin
            if (stage_out[COUNT_WIDTH][1<<k]) begin
                final_count[k] = 1'b1;
            end
        end
    end
    
    assign count_out = final_count;
endmodule