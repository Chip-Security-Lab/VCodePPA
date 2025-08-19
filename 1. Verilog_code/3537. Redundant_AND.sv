module Redundant_AND(
    input a, b,
    output y
);
    wire tmp1, tmp2;
    assign tmp1 = a & b;
    assign tmp2 = a & b;
    assign y = tmp1 & tmp2; // 冗余设计验证
endmodule
