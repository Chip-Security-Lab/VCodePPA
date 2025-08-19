//SystemVerilog
module gray_range_detector(
    input wire clk,
    input wire [7:0] gray_input,
    input wire [7:0] gray_low, gray_high,
    output reg in_range
);
    // Pipeline registers
    reg [7:0] binary_input_p1, binary_low_p1, binary_high_p1;
    reg compare_result_p2;
    
    // Pre-compute shifted values to save logic resources
    wire [7:0] gray_shifted_input = {1'b0, gray_input[7:1]};
    wire [7:0] gray_shifted_low = {1'b0, gray_low[7:1]};
    wire [7:0] gray_shifted_high = {1'b0, gray_high[7:1]};
    
    // Combined pipeline stages in a single always block
    always @(posedge clk) begin
        // First stage: Gray to binary conversion
        binary_input_p1 <= gray_input ^ gray_shifted_input;
        binary_low_p1 <= gray_low ^ gray_shifted_low;
        binary_high_p1 <= gray_high ^ gray_shifted_high;
        
        // Second stage: Comparison logic
        compare_result_p2 <= (binary_input_p1 >= binary_low_p1) && (binary_input_p1 <= binary_high_p1);
        
        // Final output stage
        in_range <= compare_result_p2;
    end
endmodule