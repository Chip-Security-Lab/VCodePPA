module Compare_XNOR(
    input [7:0] a, b,
    output eq_flag
);
    assign eq_flag = (a == b); // 比较器式实现
endmodule
