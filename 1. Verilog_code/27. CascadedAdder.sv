module Adder_5(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    // Corrected implementation - properly handle 5-bit sum
    assign sum = A + B;
endmodule