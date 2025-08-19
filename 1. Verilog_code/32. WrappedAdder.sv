module Adder_10(
    input [3:0] A,
    input [3:0] B,
    output [4:0] sum
);
    wire [4:0] temp_sum;
    assign temp_sum = A + B;
    assign sum = temp_sum;
endmodule
