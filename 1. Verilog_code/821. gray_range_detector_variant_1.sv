//SystemVerilog
module gray_range_detector(
    input wire clk,
    input wire [7:0] gray_input,
    input wire [7:0] gray_low, gray_high,
    output reg in_range
);
    // Register inputs
    reg [7:0] gray_input_reg, gray_low_reg, gray_high_reg;
    
    always @(posedge clk) begin
        gray_input_reg <= gray_input;
        gray_low_reg <= gray_low;
        gray_high_reg <= gray_high;
    end
    
    // Gray to binary conversion (moved after registers)
    wire [7:0] binary_input, binary_low, binary_high;
    
    assign binary_input = gray_input_reg ^ (gray_input_reg >> 1);
    assign binary_low = gray_low_reg ^ (gray_low_reg >> 1);
    assign binary_high = gray_high_reg ^ (gray_high_reg >> 1);
    
    // Range comparison 
    always @(posedge clk) begin
        in_range <= (binary_input >= binary_low) && (binary_input <= binary_high);
    end
endmodule