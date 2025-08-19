module EnNor(input en, a, b, output y);
    assign y = en ? ~(a | b) : 1'b0; // 使能控制
endmodule