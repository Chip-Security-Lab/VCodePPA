module nor3_generate (
    input wire A, B, C,
    output wire Y
);
    generate
        assign Y = ~(A | B | C);  // 使用 generate 块
    endgenerate
endmodule
