module mul_add (
    input [3:0] num1,
    input [3:0] num2,
    output [7:0] product,
    output [4:0] sum
);
    assign product = num1 * num2;
    assign sum = num1 + num2;
endmodule
