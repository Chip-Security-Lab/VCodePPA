module carry_save_adder (
    input  [3:0] a, b, c,
    output [3:0] sum,
    output [3:0] carry
);
    assign sum = a ^ b ^ c;
    assign carry = (a & b) | (b & c) | (a & c);
endmodule