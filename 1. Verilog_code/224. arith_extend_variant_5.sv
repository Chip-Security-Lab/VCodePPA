//SystemVerilog
module arith_extend (
    input [3:0] operand,
    output [4:0] inc,
    output [4:0] dec
);
    // 简化自增实现 - 使用更直接的进位传播逻辑
    wire [4:0] operand_ext;
    wire [4:0] carry;
    
    // 扩展操作数到5位
    assign operand_ext = {1'b0, operand};
    
    // 简化的进位生成逻辑
    assign carry[0] = 1'b1; // 初始进位
    assign carry[1] = operand_ext[0];
    assign carry[2] = operand_ext[1] & operand_ext[0];
    assign carry[3] = operand_ext[2] & operand_ext[1] & operand_ext[0];
    assign carry[4] = operand_ext[3] & operand_ext[2] & operand_ext[1] & operand_ext[0];
    
    // 简化的增量计算
    assign inc[0] = ~operand_ext[0];
    assign inc[1] = operand_ext[1] ^ carry[1];
    assign inc[2] = operand_ext[2] ^ carry[2];
    assign inc[3] = operand_ext[3] ^ carry[3];
    assign inc[4] = operand_ext[4] ^ carry[4];
    
    // 自减操作优化 - 直接实现
    // 利用减1的特性：最低位为1的位变为0，其右边所有0变为1
    wire [4:0] bitmask;
    
    // 找到最低的1位并创建位掩码
    assign bitmask[0] = operand_ext[0];
    assign bitmask[1] = ~operand_ext[0] & operand_ext[1];
    assign bitmask[2] = ~operand_ext[1] & ~operand_ext[0] & operand_ext[2];
    assign bitmask[3] = ~operand_ext[2] & ~operand_ext[1] & ~operand_ext[0] & operand_ext[3];
    assign bitmask[4] = ~operand_ext[3] & ~operand_ext[2] & ~operand_ext[1] & ~operand_ext[0] & operand_ext[4];
    
    // 计算减1的结果
    assign dec[0] = ~operand_ext[0];
    assign dec[1] = bitmask[1] ? 1'b0 : operand_ext[1];
    assign dec[2] = bitmask[2] ? 1'b0 : (bitmask[1] | bitmask[0]) ? 1'b1 : operand_ext[2];
    assign dec[3] = bitmask[3] ? 1'b0 : (bitmask[2] | bitmask[1] | bitmask[0]) ? 1'b1 : operand_ext[3];
    assign dec[4] = bitmask[4] ? 1'b0 : (bitmask[3] | bitmask[2] | bitmask[1] | bitmask[0]) ? 1'b1 : operand_ext[4];
    
endmodule