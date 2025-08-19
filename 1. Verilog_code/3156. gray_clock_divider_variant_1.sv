//SystemVerilog
module gray_clock_divider(
    input clock,
    input reset,
    output [3:0] gray_out
);
    reg [3:0] count;
    wire [3:0] next_count;
    
    // Han-Carlson加法器实现
    wire [3:0] p, g; // 生成和传播信号
    wire [3:0] p_mid, g_mid; // 中间生成和传播信号
    wire [3:0] carry;
    
    // 预处理阶段 - 生成P和G
    assign p[0] = count[0] ^ 1'b1;
    assign p[1] = count[1] ^ 1'b0;
    assign p[2] = count[2] ^ 1'b0;
    assign p[3] = count[3] ^ 1'b0;
    
    assign g[0] = count[0] & 1'b1;
    assign g[1] = count[1] & 1'b0;
    assign g[2] = count[2] & 1'b0;
    assign g[3] = count[3] & 1'b0;
    
    // 前缀计算阶段 - Han-Carlson模式（偶数位）
    assign g_mid[0] = g[0];
    assign g_mid[2] = g[2] | (p[2] & g[0]);
    
    assign p_mid[0] = p[0];
    assign p_mid[2] = p[2] & p[0];
    
    // 前缀计算阶段 - Han-Carlson模式（奇数位）
    assign g_mid[1] = g[1] | (p[1] & g[0]);
    assign g_mid[3] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[0]);
    
    assign p_mid[1] = p[1] & p[0];
    assign p_mid[3] = p[3] & p[2] & p[0];
    
    // 进位计算
    assign carry[0] = g_mid[0];
    assign carry[1] = g_mid[1];
    assign carry[2] = g_mid[2];
    assign carry[3] = g_mid[3];
    
    // 求和阶段
    assign next_count[0] = count[0] ^ 1'b1;
    assign next_count[1] = count[1] ^ carry[0];
    assign next_count[2] = count[2] ^ carry[1];
    assign next_count[3] = count[3] ^ carry[2];
    
    // 计数器更新
    always @(posedge clock) begin
        if (reset)
            count <= 4'b0000;
        else
            count <= next_count;
    end
    
    // 灰码输出
    assign gray_out = {count[3], count[3]^count[2], count[2]^count[1], count[1]^count[0]};
endmodule