//SystemVerilog
module xor_difference_detector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] pattern_a,
    input [WIDTH-1:0] pattern_b,
    output [WIDTH-1:0] difference_map,
    output exact_match,
    output [$clog2(WIDTH+1)-1:0] hamming_distance
);

    // Stage 1: Difference Detection
    wire [WIDTH-1:0] diff_map;
    assign diff_map = pattern_a ^ pattern_b;
    assign difference_map = diff_map;
    
    // Stage 2: Exact Match Detection
    wire match;
    assign match = (diff_map == {WIDTH{1'b0}});
    assign exact_match = match;
    
    // Stage 3: Bit Pair Summation
    wire [$clog2(WIDTH+1)-1:0] pair_sums [(WIDTH+1)/2-1:0];
    genvar i;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: gen_pairs
            assign pair_sums[i] = {1'b0, diff_map[i*2]} + {1'b0, diff_map[i*2+1]};
        end
        if (WIDTH % 2 == 1) begin: handle_odd
            assign pair_sums[WIDTH/2] = {1'b0, diff_map[WIDTH-1]};
        end
    endgenerate
    
    // Stage 4: Parallel Adder Tree
    wire [$clog2(WIDTH+1)-1:0] tree_sums [(WIDTH+1)/2-1:0];
    generate
        if ((WIDTH+1)/2 > 1) begin: gen_tree
            assign tree_sums[0] = pair_sums[0];
            genvar j;
            for (j = 1; j < (WIDTH+1)/2; j = j + 1) begin: gen_adders
                assign tree_sums[j] = tree_sums[j-1] + pair_sums[j];
            end
        end else begin: single_sum
            assign tree_sums[0] = pair_sums[0];
        end
    endgenerate
    
    // Stage 5: Final Hamming Distance
    assign hamming_distance = tree_sums[(WIDTH+1)/2-1];
    
endmodule