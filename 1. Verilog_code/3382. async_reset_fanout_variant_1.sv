//SystemVerilog
// 顶层模块
module async_reset_fanout (
    input  wire        async_rst_in,
    output wire [15:0] rst_out
);
    // 实例化两个8位的复位扇出子模块
    wire [7:0] rst_out_low, rst_out_high;
    
    reset_fanout_stage #(
        .WIDTH(8)
    ) u_reset_fanout_low (
        .rst_in  (async_rst_in),
        .rst_out (rst_out_low)
    );
    
    reset_fanout_stage #(
        .WIDTH(8)
    ) u_reset_fanout_high (
        .rst_in  (async_rst_in),
        .rst_out (rst_out_high)
    );
    
    // 连接输出
    assign rst_out = {rst_out_high, rst_out_low};
    
endmodule

// 复位扇出子模块
module reset_fanout_stage #(
    parameter WIDTH = 8
)(
    input  wire             rst_in,
    output wire [WIDTH-1:0] rst_out
);
    // 复位信号缓冲
    wire rst_buffered;
    
    // 创建中间缓冲以减少扇出负载
    reset_buffer u_buffer (
        .rst_in  (rst_in),
        .rst_out (rst_buffered)
    );
    
    // 将缓冲后的复位信号扇出到所有输出
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_rst
            assign rst_out[i] = rst_buffered;
        end
    endgenerate
    
endmodule

// 复位信号缓冲模块使用Kogge-Stone加法器实现
module reset_buffer (
    input  wire rst_in,
    output wire rst_out
);
    // 使用Kogge-Stone加法器作为缓冲增强驱动能力
    wire [15:0] a, b, sum;
    
    // 输入设置为固定值，以便在rst_in为高时产生进位传播
    assign a = {16{rst_in}};
    assign b = 16'h0001;
    
    // Kogge-Stone加法器实现
    wire [15:0] p_stage0, g_stage0;
    wire [15:0] p_stage1, g_stage1;
    wire [15:0] p_stage2, g_stage2;
    wire [15:0] p_stage3, g_stage3;
    wire [15:0] p_stage4, g_stage4;
    wire [15:0] carry;
    
    // 预处理阶段：生成p和g信号
    assign p_stage0 = a ^ b;
    assign g_stage0 = a & b;
    
    // 阶段1：距离1组合
    assign p_stage1[0] = p_stage0[0];
    assign g_stage1[0] = g_stage0[0];
    
    genvar i;
    generate
        for (i = 1; i < 16; i = i + 1) begin : stage1_gen
            assign p_stage1[i] = p_stage0[i] & p_stage0[i-1];
            assign g_stage1[i] = g_stage0[i] | (p_stage0[i] & g_stage0[i-1]);
        end
    endgenerate
    
    // 阶段2：距离2组合
    assign p_stage2[0] = p_stage1[0];
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[0] = g_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    
    generate
        for (i = 2; i < 16; i = i + 1) begin : stage2_gen
            assign p_stage2[i] = p_stage1[i] & p_stage1[i-2];
            assign g_stage2[i] = g_stage1[i] | (p_stage1[i] & g_stage1[i-2]);
        end
    endgenerate
    
    // 阶段3：距离4组合
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : stage3_init
            assign p_stage3[j] = p_stage2[j];
            assign g_stage3[j] = g_stage2[j];
        end
        
        for (j = 4; j < 16; j = j + 1) begin : stage3_gen
            assign p_stage3[j] = p_stage2[j] & p_stage2[j-4];
            assign g_stage3[j] = g_stage2[j] | (p_stage2[j] & g_stage2[j-4]);
        end
    endgenerate
    
    // 阶段4：距离8组合
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : stage4_init
            assign p_stage4[k] = p_stage3[k];
            assign g_stage4[k] = g_stage3[k];
        end
        
        for (k = 8; k < 16; k = k + 1) begin : stage4_gen
            assign p_stage4[k] = p_stage3[k] & p_stage3[k-8];
            assign g_stage4[k] = g_stage3[k] | (p_stage3[k] & g_stage3[k-8]);
        end
    endgenerate
    
    // 计算进位
    assign carry[0] = g_stage0[0];
    
    generate
        for (i = 1; i < 16; i = i + 1) begin : carry_gen
            assign carry[i] = g_stage4[i-1];
        end
    endgenerate
    
    // 计算和
    assign sum = p_stage0 ^ {carry[14:0], 1'b0};
    
    // 使用加法器的进位链作为复位信号缓冲
    assign rst_out = |sum & rst_in;
    
endmodule