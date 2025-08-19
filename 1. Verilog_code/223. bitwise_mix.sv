module bitwise_mix (
    input [7:0] data_a,
    input [7:0] data_b,
    output [7:0] xor_out,
    output [7:0] nand_out
);
    assign xor_out = data_a ^ data_b;
    assign nand_out = ~(data_a & data_b);
endmodule
