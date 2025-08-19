module gray_range_detector(
    input wire clk,
    input wire [7:0] gray_input,
    input wire [7:0] gray_low, gray_high,
    output reg in_range
);
    wire [7:0] binary_input, binary_low, binary_high;
    wire result;
    
    // Gray to binary conversion
    assign binary_input = gray_input ^ (gray_input >> 1);
    assign binary_low = gray_low ^ (gray_low >> 1);
    assign binary_high = gray_high ^ (gray_high >> 1);
    
    assign result = (binary_input >= binary_low) && (binary_input <= binary_high);
    
    always @(posedge clk) in_range <= result;
endmodule