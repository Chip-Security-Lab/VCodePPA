//SystemVerilog
module range_detector_async(
    input wire [15:0] data_in,
    input wire [15:0] min_val, max_val,
    output reg within_range
);
    // Optimized implementation using sequential checking
    // and early termination for better timing and area
    
    always @(*) begin
        if (min_val > max_val) begin
            // Invalid range case, return false
            within_range = 1'b0;
        end
        else if (min_val == max_val) begin
            // Special case: exact match check
            within_range = (data_in == min_val);
        end
        else begin
            // Normal range check - optimized for parallel comparison
            within_range = (data_in >= min_val) && (data_in <= max_val);
        end
    end
endmodule