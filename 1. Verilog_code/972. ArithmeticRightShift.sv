module ArithmeticRightShift #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input shift_amount,
    output [WIDTH-1:0] data_out
);
assign data_out = $signed(data_in) >>> shift_amount;
endmodule