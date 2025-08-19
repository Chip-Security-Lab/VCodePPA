module arith_extend (
    input [3:0] operand,
    output [4:0] inc,
    output [4:0] dec
);
    assign inc = operand + 1'b1;
    assign dec = operand - 1'b1;
endmodule

