module xor_difference_detector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] pattern_a,
    input [WIDTH-1:0] pattern_b,
    output [WIDTH-1:0] difference_map,  // Bitwise differences (1 where bits differ)
    output exact_match,                 // High when all bits match
    output reg [$clog2(WIDTH+1)-1:0] hamming_distance // Number of different bits
);
    // XOR finds differences between bits
    assign difference_map = pattern_a ^ pattern_b;
    
    // Exact match when no bits differ
    assign exact_match = (difference_map == {WIDTH{1'b0}});
    
    // Calculate Hamming distance (number of 1's in difference_map)
    integer i;
    always @(*) begin
        hamming_distance = 0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (difference_map[i])
                hamming_distance = hamming_distance + 1;
        end
    end
endmodule