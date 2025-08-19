//SystemVerilog
module CarryDiv(
    input [3:0] D, d,
    output [3:0] q
);
    wire borrow;
    
    // 直接计算不够借位标志
    assign borrow = (D < d);
    
    // 简化输出逻辑，移除不必要的加法和条件判断
    // 结果为0或1，与原代码功能一致
    assign q = {3'b000, borrow ? 1'b0 : 1'b1};
endmodule