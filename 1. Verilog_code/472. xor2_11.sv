module xor2_11 (
    input wire A, B,
    output wire Y
);
    wire and_out, or_out;
    and (and_out, A, B);
    or (or_out, A, B);
    assign Y = or_out & ~and_out; // 利用AND与OR组合实现异或
endmodule
