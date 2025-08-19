//SystemVerilog
module key_expansion #(parameter KEY_WIDTH = 32, EXPANDED_WIDTH = 128) (
    input wire clk, rst_n,
    input wire key_load,
    input wire [KEY_WIDTH-1:0] key_in,
    output reg [EXPANDED_WIDTH-1:0] expanded_key,
    output reg key_ready
);
    reg [2:0] stage;
    reg [KEY_WIDTH-1:0] key_reg;
    
    // 并行前缀减法器相关信号
    wire [2:0] a, b, diff;
    wire [2:0] p, g;
    wire [2:0] p_stage1, g_stage1;
    wire [2:0] p_stage2, g_stage2;
    wire [3:0] carry;
    wire [KEY_WIDTH-1:0] expansion_result;
    
    // 状态控制逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            stage <= 0;
        end else if (key_load) begin
            stage <= 1;
        end else if (stage > 0 && stage < 5) begin
            stage <= stage + 1;
        end
    end
    
    // 密钥寄存逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            key_reg <= 0;
        end else if (key_load) begin
            key_reg <= key_in;
        end
    end
    
    // key_ready 控制逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            key_ready <= 0;
        end else if (key_load) begin
            key_ready <= 0;
        end else if (stage == 4) begin
            key_ready <= 1;
        end
    end
    
    // 扩展密钥更新逻辑
    always @(posedge clk) begin
        if (!rst_n) begin
            expanded_key <= 0;
        end else if (stage > 0 && stage < 5) begin
            expanded_key[(stage-1)*KEY_WIDTH +: KEY_WIDTH] <= expansion_result;
        end
    end
    
    // 密钥扩展计算逻辑 - 组合逻辑部分
    assign expansion_result = (key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h01 << (stage-1), 24'h0}) - {29'b0, diff};
    
    // 并行前缀减法器 - 阶段选择
    assign a = stage[2:0];
    assign b = 3'b001; // 固定减数为1
    
    // 并行前缀减法器 - 初始传播(p)和生成(g)信号
    assign p = a ^ b;
    assign g = a & ~b;
    
    // 并行前缀减法器 - 阶段1前缀计算
    assign p_stage1[0] = p[0];
    assign g_stage1[0] = g[0];
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[2] = p[2] & p[1] & p[0];
    assign g_stage1[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]);
    
    // 并行前缀减法器 - 阶段2前缀计算
    assign p_stage2 = p_stage1;
    assign g_stage2 = g_stage1;
    
    // 并行前缀减法器 - 进位计算
    assign carry[0] = 1'b1; // 减法的初始借位是1
    assign carry[1] = g_stage2[0] | (p_stage2[0] & carry[0]);
    assign carry[2] = g_stage2[1] | (p_stage2[1] & carry[1]);
    assign carry[3] = g_stage2[2] | (p_stage2[2] & carry[2]);
    
    // 并行前缀减法器 - 计算最终差值
    assign diff = p ^ {carry[2:0]};
endmodule