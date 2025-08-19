//SystemVerilog
module RedundantNOT(
    input a,
    output y
);
    // 直接将输入 a 连接到输出 y，消除所有冗余的非门
    // 这种优化提高了面积效率、降低了功耗并减少了延迟
    assign y = a;
endmodule