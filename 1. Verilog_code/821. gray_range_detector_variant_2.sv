//SystemVerilog
module gray_range_detector(
    input wire clk,
    input wire [7:0] gray_input,
    input wire [7:0] gray_low, gray_high,
    output reg in_range
);
    // Gray-to-binary conversion signals
    wire [7:0] binary_input, binary_low, binary_high;
    
    // Direct combinational conversion to reduce pipeline stages
    assign binary_input = gray_input ^ {1'b0, gray_input[7:1]};
    assign binary_low = gray_low ^ {1'b0, gray_low[7:1]};
    assign binary_high = gray_high ^ {1'b0, gray_high[7:1]};
    
    // Single-stage range comparison using parallel magnitude comparators
    wire in_range_comb;
    assign in_range_comb = (binary_input >= binary_low) && (binary_input <= binary_high);
    
    // Register the final output
    always @(posedge clk) begin
        in_range <= in_range_comb;
    end
endmodule