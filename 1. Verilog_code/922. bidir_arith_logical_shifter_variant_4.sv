//SystemVerilog
module bidir_arith_logical_shifter (
    input  [31:0] src,
    input  [4:0]  amount,
    input         direction,  // 0=left, 1=right
    input         arith_mode, // 0=logical, 1=arithmetic
    output [31:0] result
);
    // 桶形移位器实现
    wire [31:0] stage_in;
    wire [31:0] stage0_out, stage1_out, stage2_out, stage3_out, stage4_out;
    wire sign_bit;
    
    // 根据移位方向准备输入数据
    assign sign_bit = src[31];
    assign stage_in = direction ? src : {src[0], src[1], src[2], src[3], src[4], src[5], src[6], src[7],
                                         src[8], src[9], src[10], src[11], src[12], src[13], src[14], src[15],
                                         src[16], src[17], src[18], src[19], src[20], src[21], src[22], src[23],
                                         src[24], src[25], src[26], src[27], src[28], src[29], src[30], src[31]};
    
    // 第一级桶形移位器 (1-bit)
    wire [31:0] stage0_fill;
    assign stage0_fill = direction ? 
                         (arith_mode ? {32{sign_bit}} : 32'b0) : 
                         32'b0;
    
    assign stage0_out = amount[0] ? 
                         (direction ? {stage0_fill[0], stage_in[31:1]} : {stage_in[30:0], stage0_fill[0]}) : 
                         stage_in;
    
    // 第二级桶形移位器 (2-bit)
    wire [31:0] stage1_fill;
    assign stage1_fill = direction ? 
                         (arith_mode ? {32{sign_bit}} : 32'b0) : 
                         32'b0;
    
    assign stage1_out = amount[1] ? 
                         (direction ? {stage1_fill[1:0], stage0_out[31:2]} : {stage0_out[29:0], stage1_fill[1:0]}) : 
                         stage0_out;
    
    // 第三级桶形移位器 (4-bit)
    wire [31:0] stage2_fill;
    assign stage2_fill = direction ? 
                         (arith_mode ? {32{sign_bit}} : 32'b0) : 
                         32'b0;
    
    assign stage2_out = amount[2] ? 
                         (direction ? {stage2_fill[3:0], stage1_out[31:4]} : {stage1_out[27:0], stage2_fill[3:0]}) : 
                         stage1_out;
    
    // 第四级桶形移位器 (8-bit)
    wire [31:0] stage3_fill;
    assign stage3_fill = direction ? 
                         (arith_mode ? {32{sign_bit}} : 32'b0) : 
                         32'b0;
    
    assign stage3_out = amount[3] ? 
                         (direction ? {stage3_fill[7:0], stage2_out[31:8]} : {stage2_out[23:0], stage3_fill[7:0]}) : 
                         stage2_out;
    
    // 第五级桶形移位器 (16-bit)
    wire [31:0] stage4_fill;
    assign stage4_fill = direction ? 
                         (arith_mode ? {32{sign_bit}} : 32'b0) : 
                         32'b0;
    
    assign stage4_out = amount[4] ? 
                         (direction ? {stage4_fill[15:0], stage3_out[31:16]} : {stage3_out[15:0], stage4_fill[15:0]}) : 
                         stage3_out;
    
    // 输出结果
    assign result = direction ? stage4_out : 
                              {stage4_out[0], stage4_out[1], stage4_out[2], stage4_out[3], 
                               stage4_out[4], stage4_out[5], stage4_out[6], stage4_out[7],
                               stage4_out[8], stage4_out[9], stage4_out[10], stage4_out[11], 
                               stage4_out[12], stage4_out[13], stage4_out[14], stage4_out[15],
                               stage4_out[16], stage4_out[17], stage4_out[18], stage4_out[19], 
                               stage4_out[20], stage4_out[21], stage4_out[22], stage4_out[23],
                               stage4_out[24], stage4_out[25], stage4_out[26], stage4_out[27], 
                               stage4_out[28], stage4_out[29], stage4_out[30], stage4_out[31]};
endmodule