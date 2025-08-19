module CascadeNor(input a, b, c, output y1, y2);
    assign y1 = ~(a | b);
    assign y2 = ~(y1 | c); // 级联结构
endmodule