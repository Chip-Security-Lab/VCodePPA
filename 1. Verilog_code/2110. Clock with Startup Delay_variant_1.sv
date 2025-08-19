//SystemVerilog
module clk_with_delay(
    input clk_in,
    input rst_n,
    input [3:0] delay_cycles,
    output reg clk_out
);
    reg [3:0] counter;
    reg running;
    
    // 前缀加法器信号定义
    wire [3:0] next_counter;
    wire [3:0] p, g; // 传播和生成信号
    wire [3:0] p_stage1, g_stage1; // 第一级传播和生成
    wire [3:0] p_stage2, g_stage2; // 第二级传播和生成
    wire [3:0] carry; // 进位信号
    
    // 生成初始的传播和生成信号
    assign p = counter;
    assign g = 4'b0000; // 初始生成为0
    
    // 前缀加法器第一级
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    
    assign p_stage1[3] = p[3] & p[2];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    
    // 前缀加法器第二级
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[0] = g_stage1[0];
    
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[1] = g_stage1[1];
    
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    
    assign p_stage2[3] = p_stage1[3] & p_stage1[1];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    
    // 计算进位
    assign carry[0] = 1'b1; // 加1的进位输入
    assign carry[1] = g_stage2[0] | (p_stage2[0] & carry[0]);
    assign carry[2] = g_stage2[1] | (p_stage2[1] & carry[1]);
    assign carry[3] = g_stage2[2] | (p_stage2[2] & carry[2]);
    
    // 计算最终结果
    assign next_counter[0] = p[0] ^ carry[0];
    assign next_counter[1] = p[1] ^ carry[1];
    assign next_counter[2] = p[2] ^ carry[2];
    assign next_counter[3] = p[3] ^ carry[3];
    
    // 处理计数器逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
        end else if (!running) begin
            if (counter >= delay_cycles) begin
                counter <= 4'd0;
            end else begin
                counter <= next_counter;
            end
        end
    end
    
    // 处理运行状态控制逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            running <= 1'b0;
        end else if (!running) begin
            if (counter >= delay_cycles) begin
                running <= 1'b1;
            end
        end
    end
    
    // 处理时钟输出逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out <= 1'b0;
        end else if (running) begin
            clk_out <= ~clk_out;
        end
    end
endmodule