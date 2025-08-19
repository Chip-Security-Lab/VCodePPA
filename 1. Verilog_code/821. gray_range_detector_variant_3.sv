//SystemVerilog
module gray_range_detector(
    input wire clk,
    input wire [7:0] gray_input,
    input wire [7:0] gray_low, gray_high,
    output reg in_range
);
    // Gray to binary conversion - first stage pipeline
    reg [7:0] binary_input_s1, binary_low_s1, binary_high_s1;
    
    // First stage - convert gray code to binary with optimized bitwise operations
    wire [7:0] binary_input = gray_input ^ {1'b0, gray_input[7:1]};
    wire [7:0] binary_low = gray_low ^ {1'b0, gray_low[7:1]};
    wire [7:0] binary_high = gray_high ^ {1'b0, gray_high[7:1]};
    
    // Register binary conversions in first pipeline stage
    always @(posedge clk) begin
        binary_input_s1 <= binary_input;
        binary_low_s1 <= binary_low;
        binary_high_s1 <= binary_high;
    end
    
    // Split comparison to balance paths - second stage
    reg low_check_s2, high_check_s2;
    
    // Break down comparisons into smaller parallel operations
    // Register comparison results in second pipeline stage
    always @(posedge clk) begin
        low_check_s2 <= (binary_input_s1 >= binary_low_s1);
        high_check_s2 <= (binary_input_s1 <= binary_high_s1);
    end
    
    // Final stage - combine results
    always @(posedge clk) begin
        in_range <= low_check_s2 && high_check_s2;
    end
endmodule