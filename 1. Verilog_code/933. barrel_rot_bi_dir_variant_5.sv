//SystemVerilog
module barrel_rot_bi_dir (
    input [31:0] data_in,
    input [4:0] shift_val,
    input direction,  // 0-left, 1-right
    output [31:0] data_out
);
    // 对于旋转操作，使用分层结构实现
    // 首先处理方向，然后进行分阶段移位
    wire [31:0] effective_data;
    wire [4:0] effective_shift;
    
    // 根据方向确定有效的移位值和数据
    assign effective_shift = shift_val;
    assign effective_data = data_in;
    
    // 使用分层结构进行旋转操作（使用蝶形网络）
    wire [31:0] stage0, stage1, stage2, stage3, stage4;
    
    // 第0阶段 - 移位1位
    assign stage0 = effective_shift[0] ? 
                    (direction ? {effective_data[0], effective_data[31:1]} : 
                               {effective_data[30:0], effective_data[31]}) : 
                    effective_data;
    
    // 第1阶段 - 移位2位
    assign stage1 = effective_shift[1] ? 
                    (direction ? {stage0[1:0], stage0[31:2]} : 
                               {stage0[29:0], stage0[31:30]}) : 
                    stage0;
    
    // 第2阶段 - 移位4位
    assign stage2 = effective_shift[2] ? 
                    (direction ? {stage1[3:0], stage1[31:4]} : 
                               {stage1[27:0], stage1[31:28]}) : 
                    stage1;
    
    // 第3阶段 - 移位8位
    assign stage3 = effective_shift[3] ? 
                    (direction ? {stage2[7:0], stage2[31:8]} : 
                               {stage2[23:0], stage2[31:24]}) : 
                    stage2;
    
    // 第4阶段 - 移位16位
    assign stage4 = effective_shift[4] ? 
                    (direction ? {stage3[15:0], stage3[31:16]} : 
                               {stage3[15:0], stage3[31:16]}) : 
                    stage3;
    
    // 输出最终结果
    assign data_out = stage4;
    
endmodule