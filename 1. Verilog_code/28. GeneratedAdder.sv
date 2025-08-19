module Adder_6(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    // Corrected implementation - removed invalid generate statement
    assign sum = A + B;
endmodule