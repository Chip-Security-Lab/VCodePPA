//SystemVerilog
module barrel_rot_bi_dir (
    input [31:0] data_in,
    input [4:0] shift_val,
    input direction,  // 0-left, 1-right
    output [31:0] data_out
);
    // 使用分层MUX结构实现旋转操作，减少延迟
    wire [31:0] stage0_left, stage0_right;
    wire [31:0] stage1_left, stage1_right;
    wire [31:0] stage2_left, stage2_right;
    wire [31:0] stage3_left, stage3_right;
    wire [31:0] stage4_left, stage4_right;
    
    // 第1级 - 移位1位
    assign stage0_left = shift_val[0] ? {data_in[30:0], data_in[31]} : data_in;
    assign stage0_right = shift_val[0] ? {data_in[0], data_in[31:1]} : data_in;
    
    // 第2级 - 移位2位
    assign stage1_left = shift_val[1] ? {stage0_left[29:0], stage0_left[31:30]} : stage0_left;
    assign stage1_right = shift_val[1] ? {stage0_right[1:0], stage0_right[31:2]} : stage0_right;
    
    // 第3级 - 移位4位
    assign stage2_left = shift_val[2] ? {stage1_left[27:0], stage1_left[31:28]} : stage1_left;
    assign stage2_right = shift_val[2] ? {stage1_right[3:0], stage1_right[31:4]} : stage1_right;
    
    // 第4级 - 移位8位
    assign stage3_left = shift_val[3] ? {stage2_left[23:0], stage2_left[31:24]} : stage2_left;
    assign stage3_right = shift_val[3] ? {stage2_right[7:0], stage2_right[31:8]} : stage2_right;
    
    // 第5级 - 移位16位
    assign stage4_left = shift_val[4] ? {stage3_left[15:0], stage3_left[31:16]} : stage3_left;
    assign stage4_right = shift_val[4] ? {stage3_right[15:0], stage3_right[31:16]} : stage3_right;
    
    // 最终输出选择
    assign data_out = direction ? stage4_right : stage4_left;
endmodule