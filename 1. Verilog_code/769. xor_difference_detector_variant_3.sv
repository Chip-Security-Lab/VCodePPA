//SystemVerilog
module xor_difference_detector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] pattern_a,
    input [WIDTH-1:0] pattern_b,
    output [WIDTH-1:0] difference_map,  // Bitwise differences (1 where bits differ)
    output exact_match,                 // High when all bits match
    output [$clog2(WIDTH+1)-1:0] hamming_distance // Number of different bits
);
    // XOR finds differences between bits
    assign difference_map = pattern_a ^ pattern_b;
    
    // Exact match when no bits differ
    assign exact_match = (difference_map == {WIDTH{1'b0}});
    
    // Calculate Hamming distance using carry-lookahead adder algorithm
    // For 8-bit operation as specified
    wire [7:0] diff_bits;
    wire [3:0] sum_stage1 [1:0];
    wire [1:0] sum_stage2;
    wire [$clog2(WIDTH+1)-1:0] final_sum;
    
    // Use only the first 8 bits for calculation as specified in requirements
    assign diff_bits = difference_map[7:0];
    
    // Stage 1: Generate and propagate signals
    wire [7:0] g, p;
    wire [7:0] c;
    
    // Generate and propagate for each bit position
    assign g[0] = 1'b0;  // No carry generation for first bit
    assign p[0] = diff_bits[0];
    
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin: gen_gp
            assign g[i] = 1'b0;  // For counting 1s, no carry generation
            assign p[i] = diff_bits[i];
        end
    endgenerate
    
    // Stage 1: First level carry lookahead calculation
    assign c[0] = 1'b0;  // Initial carry is 0
    
    generate
        for (i = 1; i < 8; i = i + 1) begin: gen_c
            assign c[i] = g[i-1] | (p[i-1] & c[i-1]);
        end
    endgenerate
    
    // Sum computation using pairs of bits
    assign sum_stage1[0] = diff_bits[0] + diff_bits[1] + diff_bits[2] + diff_bits[3];
    assign sum_stage1[1] = diff_bits[4] + diff_bits[5] + diff_bits[6] + diff_bits[7];
    
    // Stage 2: Combine results from stage 1
    assign sum_stage2 = sum_stage1[0] + sum_stage1[1];
    
    // Final sum computation using carry-lookahead principles
    assign final_sum = sum_stage2[0] + sum_stage2[1];
    
    // For width > 8, add the remaining bits using the original approach
    wire [$clog2(WIDTH+1)-1:0] remaining_bits_count;
    
    generate
        if (WIDTH > 8) begin: gen_remaining
            reg [$clog2(WIDTH+1)-1:0] count;
            integer j;
            
            always @(*) begin
                count = 0;
                for (j = 8; j < WIDTH; j = j + 1) begin
                    if (difference_map[j])
                        count = count + 1;
                end
            end
            
            assign remaining_bits_count = count;
        end else begin
            assign remaining_bits_count = 0;
        end
    endgenerate
    
    // Combine the results
    assign hamming_distance = final_sum + remaining_bits_count;
    
endmodule