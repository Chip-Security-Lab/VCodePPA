module Redundant_XNOR(
    input x, y,
    output z
);
    wire t1 = ~(x ^ y);
    wire t2 = x ~^ y;
    assign z = t1 & t2; // 双路径验证
endmodule
