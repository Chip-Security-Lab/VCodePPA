module shift_right_arithmetic #(parameter WIDTH=8) (
    input clk, en,
    input signed [WIDTH-1:0] data_in,
    input [2:0] shift,
    output reg signed [WIDTH-1:0] data_out
);
always @(posedge clk) if(en) 
    data_out <= data_in >>> shift;
endmodule