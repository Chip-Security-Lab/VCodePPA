module BiNor(inout a, b, y);
    assign y = ~(a | b); // 双向信号处理
endmodule