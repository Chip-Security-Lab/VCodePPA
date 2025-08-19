module MultiNor(input a, b, c, output y);
    assign y = ~(a | b | c); // 3输入扩展
endmodule