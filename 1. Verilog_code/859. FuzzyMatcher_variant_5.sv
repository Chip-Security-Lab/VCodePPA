//SystemVerilog
module FuzzyMatcher #(parameter WIDTH=8, THRESHOLD=2) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output match
);

    // XOR to find different bits
    wire [WIDTH-1:0] xor_result = data ^ pattern;
    
    // Optimized bit counting using parallel reduction
    wire [7:0] ones_count;
    
    // First level: Count bits in pairs
    wire [WIDTH/2-1:0] pair_counts;
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : gen_pair_counts
            assign pair_counts[i] = xor_result[2*i] + xor_result[2*i+1];
        end
    endgenerate
    
    // Second level: Sum pairs using tree structure
    wire [3:0] sum_level1;
    wire [1:0] sum_level2;
    
    // Level 1 sums
    assign sum_level1[0] = pair_counts[0] + pair_counts[1];
    assign sum_level1[1] = pair_counts[2] + pair_counts[3];
    assign sum_level1[2] = (WIDTH > 8) ? (pair_counts[4] + pair_counts[5]) : 2'b0;
    assign sum_level1[3] = (WIDTH > 8) ? (pair_counts[6] + pair_counts[7]) : 2'b0;
    
    // Level 2 sums
    assign sum_level2[0] = sum_level1[0] + sum_level1[1];
    assign sum_level2[1] = sum_level1[2] + sum_level1[3];
    
    // Final sum
    assign ones_count = sum_level2[0] + sum_level2[1];
    
    // Match if the number of different bits is less than or equal to threshold
    assign match = (ones_count <= THRESHOLD);

endmodule