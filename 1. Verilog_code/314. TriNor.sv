module TriNor(input en, a, b, output y);
    assign y = en ? ~(a | b) : 1'bz; // 高阻态控制
endmodule