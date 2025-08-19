module CondNor(input a, b, output y);
    assign y = (a|b) ? 0 : 1; // 等效逻辑
endmodule
