//SystemVerilog
module subtract_shift_right (
    input [7:0] a,
    input [7:0] b,
    input [2:0] shift_amount,
    output [7:0] difference,
    output [7:0] shifted_result
);
    wire [7:0] b_complement;
    wire [7:0] shift_stage1, shift_stage2;
    
    // 生成b的二进制补码（取反加一）
    assign b_complement = ~b + 8'b00000001;
    
    // 使用补码加法实现减法: a - b = a + (~b + 1)
    assign difference = a + b_complement;
    
    // 使用桶形移位器实现可变右移
    // 第一级移位 - 移1位
    assign shift_stage1 = shift_amount[0] ? {1'b0, a[7:1]} : a;
    
    // 第二级移位 - 移2位
    assign shift_stage2 = shift_amount[1] ? {2'b00, shift_stage1[7:2]} : shift_stage1;
    
    // 第三级移位 - 移4位
    assign shifted_result = shift_amount[2] ? {4'b0000, shift_stage2[7:4]} : shift_stage2;
endmodule