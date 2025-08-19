module Adder_4(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    wire [4:0] result;
    assign result = A + B;
    assign sum = result;
endmodule
