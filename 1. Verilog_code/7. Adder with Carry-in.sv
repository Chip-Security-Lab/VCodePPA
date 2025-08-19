module adder_with_carry (
    input  [3:0] a, b,
    input        cin,
    output [3:0] sum,
    output       carry
);
    assign {carry, sum} = a + b + cin;
endmodule