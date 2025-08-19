module generic_mult #(parameter WIDTH=8) (
    input [WIDTH-1:0] operand1,
    input [WIDTH-1:0] operand2,
    output [2*WIDTH-1:0] product
);
    assign product = operand1 * operand2;
endmodule
