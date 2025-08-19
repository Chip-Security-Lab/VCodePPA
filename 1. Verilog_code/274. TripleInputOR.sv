module TripleInputOR(
    input a, b, c,
    output out
);
    assign out = a | b | c;  // 三输入扩展
endmodule
