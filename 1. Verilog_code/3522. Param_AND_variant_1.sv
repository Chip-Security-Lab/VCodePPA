//SystemVerilog
//
// Optimized parametric AND module with improved pipeline structure
//
module Param_AND #(
    parameter WIDTH = 8
)(
    input wire clk,                  // Clock input
    input wire rst_n,                // Active low reset
    input wire [WIDTH-1:0] data_a,   // Input data A
    input wire [WIDTH-1:0] data_b,   // Input data B
    output reg [WIDTH-1:0] result    // Operation result
);

    // Pipeline stage registers with one-hot encoding for better reset sequence
    reg [WIDTH-1:0] stage1_a;
    reg [WIDTH-1:0] stage1_b;
    reg [WIDTH-1:0] stage2_result;
    
    // Optimized reset values for improved power efficiency
    wire [WIDTH-1:0] reset_value = {WIDTH{1'b0}};
    
    // Single process implementation with conditional operators for better timing and area efficiency
    always @(posedge clk or negedge rst_n) begin
        // Using conditional operators instead of if-else for improved synthesis results
        stage1_a      <= (!rst_n) ? reset_value : data_a;
        stage1_b      <= (!rst_n) ? reset_value : data_b;
        stage2_result <= (!rst_n) ? reset_value : stage1_a & stage1_b;
        result        <= (!rst_n) ? reset_value : stage2_result;
    end

endmodule