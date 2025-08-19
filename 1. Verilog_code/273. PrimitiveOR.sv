module PrimitiveOR(
    input x, y,
    output z
);
    or(z, x, y);  // 使用Verilog内置原语
endmodule
