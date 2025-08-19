module PrimitiveNOT(
    input a,
    output y
);
    not G1(y, a);  // 使用Verilog原语
endmodule
