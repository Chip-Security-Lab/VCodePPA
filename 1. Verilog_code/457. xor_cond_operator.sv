module xor_cond_operator(
    input [7:0] a,
    input [7:0] b,
    output [7:0] y
);
    assign y = a ^ b;
endmodule