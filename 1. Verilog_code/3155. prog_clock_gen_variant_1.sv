//SystemVerilog
//顶层模块
module prog_clock_gen(
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output o_clk
);
    // 内部信号
    wire count_reset;
    wire clk_toggle;
    wire [15:0] count_value;
    
    // 子模块实例化
    counter_module counter_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_enable(i_enable),
        .i_divisor(i_divisor),
        .o_count(count_value),
        .o_count_reset(count_reset),
        .o_clk_toggle(clk_toggle)
    );
    
    clock_control_module clock_ctrl_inst (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_clk_toggle(clk_toggle),
        .i_count_reset(count_reset),
        .o_clk(o_clk)
    );
    
endmodule

// 计数器子模块 - 使用曼彻斯特进位链加法器
module counter_module (
    input i_clk,
    input i_rst_n,
    input i_enable,
    input [15:0] i_divisor,
    output reg [15:0] o_count,
    output o_count_reset,
    output o_clk_toggle
);
    // 曼彻斯特进位链加法器信号
    wire [15:0] next_count;
    wire [15:0] carry_chain;
    wire [15:0] sum_bits;
    
    // 计数达到分频值时产生重置信号
    assign o_count_reset = (o_count >= i_divisor - 1) && i_enable;
    // 计数达到分频值时产生时钟切换信号
    assign o_clk_toggle = o_count_reset;
    
    // 曼彻斯特进位链加法器实现
    // 生成和传播信号
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_manchester
            // 生成信号 G[i] = A[i] & B[i]
            wire g_bit = o_count[i] & 1'b1;
            
            // 传播信号 P[i] = A[i] ^ B[i]
            wire p_bit = o_count[i] ^ 1'b1;
            
            // 进位链计算
            if (i == 0) begin
                assign carry_chain[i] = g_bit;
            end else begin
                assign carry_chain[i] = g_bit | (p_bit & carry_chain[i-1]);
            end
            
            // 和位计算 S[i] = P[i] ^ C[i-1]
            if (i == 0) begin
                assign sum_bits[i] = p_bit;
            end else begin
                assign sum_bits[i] = p_bit ^ carry_chain[i-1];
            end
        end
    endgenerate
    
    // 计算下一个计数值
    assign next_count = sum_bits;
    
    // 计数器逻辑
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_count <= 16'd0;
        end else if (i_enable) begin
            if (o_count_reset) begin
                o_count <= 16'd0;
            end else begin
                o_count <= next_count;
            end
        end
    end
endmodule

// 时钟控制子模块 - 负责输出时钟的翻转逻辑
module clock_control_module (
    input i_clk,
    input i_rst_n,
    input i_clk_toggle,
    input i_count_reset,
    output reg o_clk
);
    // 时钟翻转逻辑
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            o_clk <= 1'b0;
        end else if (i_clk_toggle) begin
            o_clk <= ~o_clk;
        end
    end
endmodule