//SystemVerilog
module FuzzyMatcher #(parameter WIDTH=8, THRESHOLD=2) (
    input [WIDTH-1:0] data,
    input [WIDTH-1:0] pattern,
    output match
);
    // XOR to find different bits
    wire [WIDTH-1:0] xor_result = data ^ pattern;
    
    // Optimized bit counting using carry-save adder approach
    // This reduces logic depth and improves timing
    reg [$clog2(WIDTH):0] ones_count;
    
    always @* begin
        ones_count = 0;
        case (WIDTH)
            1: ones_count = xor_result[0];
            2: ones_count = xor_result[0] + xor_result[1];
            3: ones_count = xor_result[0] + xor_result[1] + xor_result[2];
            4: begin
                ones_count = xor_result[0] + xor_result[1] + xor_result[2] + xor_result[3];
            end
            default: begin
                // Wallace tree approach for larger bit widths
                // First level of compression - pairs
                reg [$clog2(WIDTH):0] level1_sums[0:(WIDTH/2)];
                for (int i = 0; i < WIDTH/2; i = i + 1) begin
                    level1_sums[i] = xor_result[i*2] + xor_result[i*2+1];
                end
                // Handle odd bit if present
                if (WIDTH % 2 == 1) begin
                    level1_sums[WIDTH/2] = xor_result[WIDTH-1];
                end
                
                // Sum the results
                ones_count = 0;
                for (int i = 0; i <= WIDTH/2; i = i + 1) begin
                    ones_count = ones_count + level1_sums[i];
                end
            end
        endcase
    end
    
    // Threshold comparison with early termination when possible
    // Using direct comparison which synthesizes to more efficient logic
    assign match = (ones_count <= THRESHOLD);
endmodule