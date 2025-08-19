//SystemVerilog
module fuzzy_pattern_matcher #(parameter W = 8, MAX_MISMATCHES = 2) (
    input [W-1:0] data, pattern,
    output match
);
    // XOR to find differences between data and pattern
    wire [W-1:0] diff;
    
    // Optimized mismatch counter using one-hot encoding
    reg [$clog2(W+1)-1:0] mismatch_count;
    
    // Calculate bit differences
    assign diff = data ^ pattern;
    
    // Parallelized mismatch counting using LUT-friendly structure
    always @(*) begin: mismatch_counter
        // Use case statement for better synthesis to LUT mapping
        case (diff)
            {W{1'b0}}: mismatch_count = 0;
            default: begin
                mismatch_count = 0;
                mismatch_count = mismatch_count + diff[0];
                mismatch_count = mismatch_count + diff[1];
                mismatch_count = mismatch_count + diff[2];
                mismatch_count = mismatch_count + diff[3];
                mismatch_count = mismatch_count + diff[4];
                mismatch_count = mismatch_count + diff[5];
                mismatch_count = mismatch_count + diff[6];
                mismatch_count = mismatch_count + diff[7];
            end
        endcase
    end
    
    // Early termination comparison logic
    assign match = (mismatch_count <= MAX_MISMATCHES);
    
endmodule