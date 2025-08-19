module Adder_3(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    assign sum = {1'b0, A} + {1'b0, B}; 
endmodule
