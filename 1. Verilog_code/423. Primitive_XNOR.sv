module Primitive_XNOR(
    input x, y,
    output z
);
    xnor U1(z, x, y); // 使用Verilog原语
endmodule
