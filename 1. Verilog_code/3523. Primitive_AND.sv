module Primitive_AND(
    input x, y,
    output z
);
    and U1(z, x, y); // 使用Verilog原语实例化
endmodule
