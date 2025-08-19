module RangeDetector_BoundType #(
    parameter WIDTH = 8,
    parameter INCLUSIVE = 1 // 0:exclusive
)(
    input clk,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] lower,
    input [WIDTH-1:0] upper,
    output reg out_flag
);
always @(*) begin
    if(INCLUSIVE)
        out_flag = (data_in >= lower) && (data_in <= upper);
    else
        out_flag = (data_in > lower) && (data_in < upper);
end
endmodule