//SystemVerilog
// 顶层模块 - 优化的DES密钥调度器
module des_key_scheduler #(
    parameter KEY_WIDTH = 56,
    parameter KEY_OUT = 48
) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [5:0] round,
    output wire [KEY_OUT-1:0] subkey
);
    // 内部管道信号定义
    reg [KEY_WIDTH-1:0] key_reg;               // 输入密钥寄存
    wire [4:0] shift_amount;                   // 位移量
    wire [KEY_WIDTH-1:0] stage1_rotated_key;   // 第一阶段旋转结果
    reg [KEY_WIDTH-1:0] stage1_key_reg;        // 第一阶段寄存
    wire [KEY_OUT-1:0] stage2_subkey;          // 第二阶段压缩置换结果
    
    // 第一阶段: 密钥输入寄存和位移量计算
    always @(*) begin
        key_reg = key_in;
    end
    
    // 基于round计算位移量
    assign shift_amount = round[0] ? 5'd1 : 5'd2;
    
    // 第二阶段: 执行关键旋转操作
    key_rotation_optimized #(
        .KEY_WIDTH(KEY_WIDTH)
    ) rotation_inst (
        .key_in(key_reg),
        .shift_amount(shift_amount),
        .rotated_key(stage1_rotated_key)
    );
    
    // 旋转结果寄存 - 分割数据路径
    always @(*) begin
        stage1_key_reg = stage1_rotated_key;
    end
    
    // 第三阶段: 压缩置换操作
    compression_permutation_optimized #(
        .KEY_WIDTH(KEY_WIDTH),
        .KEY_OUT(KEY_OUT)
    ) compression_inst (
        .rotated_key(stage1_key_reg),
        .subkey(stage2_subkey)
    );
    
    // 输出赋值
    assign subkey = stage2_subkey;
    
endmodule

// 优化的密钥旋转子模块
module key_rotation_optimized #(
    parameter KEY_WIDTH = 56
) (
    input wire [KEY_WIDTH-1:0] key_in,
    input wire [4:0] shift_amount,
    output wire [KEY_WIDTH-1:0] rotated_key
);
    // 直接实现的位移逻辑，避免使用复杂的二进制补码减法
    // 对于DES，位移量通常只有1或2，使用专用逻辑更清晰
    
    // 预计算两种可能的位移结果
    wire [KEY_WIDTH-1:0] shift_by_1;
    wire [KEY_WIDTH-1:0] shift_by_2;
    
    // 左循环移位1位
    assign shift_by_1 = {key_in[KEY_WIDTH-2:0], key_in[KEY_WIDTH-1]};
    
    // 左循环移位2位
    assign shift_by_2 = {key_in[KEY_WIDTH-3:0], key_in[KEY_WIDTH-1:KEY_WIDTH-2]};
    
    // 基于位移量选择结果
    assign rotated_key = (shift_amount == 5'd1) ? shift_by_1 : shift_by_2;
    
endmodule

// 优化的压缩置换子模块
module compression_permutation_optimized #(
    parameter KEY_WIDTH = 56,
    parameter KEY_OUT = 48
) (
    input wire [KEY_WIDTH-1:0] rotated_key,
    output wire [KEY_OUT-1:0] subkey
);
    // 将压缩置换划分为多个逻辑段，提高可读性并改善时序
    wire [25:0] key_segment_high;  // 高位段数据
    wire [19:0] key_segment_mid;   // 中间段数据
    wire [9:0] key_segment_low;    // 低位段数据

    // 按段提取数据
    assign key_segment_high = rotated_key[45:20]; // 26位
    assign key_segment_mid = rotated_key[19:0];   // 20位
    assign key_segment_low = rotated_key[55:46];  // 10位
    
    // 组合成最终子密钥输出
    assign subkey = {key_segment_high, key_segment_mid, key_segment_low};
    
endmodule