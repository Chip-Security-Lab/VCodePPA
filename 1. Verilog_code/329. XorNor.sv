module XorNor(input a, b, output y);
    assign y = ~(a | b) ^ ~(a & b); // 等效表达式
endmodule