//SystemVerilog
module xor_difference_detector #(
    parameter WIDTH = 16
)(
    input [WIDTH-1:0] pattern_a,
    input [WIDTH-1:0] pattern_b,
    output [WIDTH-1:0] difference_map,
    output exact_match,
    output reg [$clog2(WIDTH+1)-1:0] hamming_distance
);

    // XOR difference detection
    wire [WIDTH-1:0] diff = pattern_a ^ pattern_b;
    assign difference_map = diff;
    
    // Exact match detection using reduction operator
    assign exact_match = ~|diff;
    
    // Optimized Hamming distance calculation using parallel prefix adder
    always @(*) begin
        reg [WIDTH-1:0] sum;
        reg [WIDTH/2-1:0] sum2;
        reg [WIDTH/4-1:0] sum4;
        reg [WIDTH/8-1:0] sum8;
        integer i;
        
        // First level - parallel 2-bit adders
        for (i = 0; i < WIDTH/2; i = i + 1) begin
            sum2[i] = diff[i*2] + diff[i*2+1];
        end
        
        // Second level - parallel 4-bit adders
        for (i = 0; i < WIDTH/4; i = i + 1) begin
            sum4[i] = sum2[i*2] + sum2[i*2+1];
        end
        
        // Third level - parallel 8-bit adders
        for (i = 0; i < WIDTH/8; i = i + 1) begin
            sum8[i] = sum4[i*2] + sum4[i*2+1];
        end
        
        // Final accumulation
        hamming_distance = 0;
        for (i = 0; i < WIDTH/8; i = i + 1) begin
            hamming_distance = hamming_distance + sum8[i];
        end
        
        // Handle remaining bits for non-power-of-2 widths
        if (WIDTH % 8) begin
            hamming_distance = hamming_distance + diff[WIDTH-1];
        end
    end

endmodule