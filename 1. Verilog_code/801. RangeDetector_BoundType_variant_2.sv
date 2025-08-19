//SystemVerilog
module RangeDetector_BoundType #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1
)(
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg out_flag
);

    wire [WIDTH:0] diff_lower;
    wire [WIDTH:0] diff_upper;
    wire lower_comp;
    wire upper_comp;

    // Conditional sum subtraction for lower bound comparison
    assign diff_lower = {1'b0, data_in} - {1'b0, lower};
    assign lower_comp = INCLUSIVE ? ~diff_lower[WIDTH] : 
                       (diff_lower[WIDTH:0] != 0) && ~diff_lower[WIDTH];

    // Conditional sum subtraction for upper bound comparison  
    assign diff_upper = {1'b0, upper} - {1'b0, data_in};
    assign upper_comp = INCLUSIVE ? ~diff_upper[WIDTH] :
                       (diff_upper[WIDTH:0] != 0) && ~diff_upper[WIDTH];

    always @(*) begin
        out_flag = lower_comp && upper_comp;
    end

endmodule