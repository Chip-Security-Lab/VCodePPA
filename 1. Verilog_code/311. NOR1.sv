module NOR1(input a, b, output y);
    assign y = ~(a | b); // 直接运算符实现
endmodule