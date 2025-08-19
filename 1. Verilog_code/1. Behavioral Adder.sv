module adder_behavioral (
    input  [3:0] a,
    input  [3:0] b,
    output [3:0] sum,
    output       carry
);
    assign {carry, sum} = a + b;
endmodule