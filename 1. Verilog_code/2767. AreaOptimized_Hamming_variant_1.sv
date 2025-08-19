//SystemVerilog
module AreaOptimized_Hamming(
    input [3:0] din,
    output [6:0] code
);
    // 数据位直接映射
    assign code[6:3] = din[3:0];
    
    // 优化校验位计算
    // 使用布尔代数规则简化表达式
    wire p0, p1;
    assign p0 = din[0] ^ din[1] ^ din[3];
    assign p1 = din[0] ^ din[2] ^ din[3];
    
    // 映射校验位到编码的相应位置
    assign code[2] = din[0];
    assign code[1] = p1;
    assign code[0] = p0;
endmodule