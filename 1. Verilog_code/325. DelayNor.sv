module DelayNor(input a, b, output y);
    assign #2 y = ~(a | b); // 仿真延时
endmodule