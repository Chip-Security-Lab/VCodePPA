module xor_2s_complement(
    input [3:0] data_in,
    output [3:0] xor_out
);
    assign xor_out = data_in ^ 4'b1111;
endmodule