module comparator(
    input [3:0] a, b,
    output gt, eq, lt
);
    assign gt = (a > b);
    assign eq = (a == b);
    assign lt = (a < b);  // 关系运算符组合
endmodule