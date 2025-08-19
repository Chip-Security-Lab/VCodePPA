module Adder_9(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    assign sum = (A + B) ? (A + B) : 0;
endmodule
