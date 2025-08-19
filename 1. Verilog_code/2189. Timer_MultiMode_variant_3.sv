//SystemVerilog
module Timer_MultiMode #(parameter MODE=0) (
    input clk, rst_n,
    input [7:0] period,
    output reg out
);
    // 管线阶段1: 计数和比较预处理
    reg [7:0] cnt_stage1;
    reg [7:0] period_stage1;
    reg [1:0] mode_stage1;
    reg valid_stage1;
    
    // 管线阶段2: 比较逻辑
    reg compare_result_stage2;
    reg [7:0] cnt_stage2;
    reg [7:0] period_stage2;
    reg [1:0] mode_stage2;
    reg valid_stage2;
    
    // Brent-Kung加法器信号
    wire [7:0] next_cnt;
    wire [7:0] p_gen, g_gen; // 生成和传播信号
    wire [7:0] g_prop; // 群组进位传播
    wire [7:0] carry; // 进位信号

    // 生成基本的生成和传播信号
    assign p_gen = cnt_stage1 ^ 8'h1;
    assign g_gen = cnt_stage1 & 8'h1;

    // 第一级群组传播计算
    assign g_prop[0] = g_gen[0];
    assign g_prop[1] = g_gen[1] | (p_gen[1] & g_gen[0]);
    assign g_prop[2] = g_gen[2];
    assign g_prop[3] = g_gen[3] | (p_gen[3] & g_gen[2]);
    assign g_prop[4] = g_gen[4];
    assign g_prop[5] = g_gen[5] | (p_gen[5] & g_gen[4]);
    assign g_prop[6] = g_gen[6];
    assign g_prop[7] = g_gen[7] | (p_gen[7] & g_gen[6]);

    // 第二级群组传播计算
    wire [7:0] g_prop_lvl2;
    assign g_prop_lvl2[1:0] = g_prop[1:0];
    assign g_prop_lvl2[2] = g_prop[2];
    assign g_prop_lvl2[3] = g_prop[3] | (p_gen[3] & p_gen[2] & g_prop[1]);
    assign g_prop_lvl2[5:4] = g_prop[5:4];
    assign g_prop_lvl2[6] = g_prop[6];
    assign g_prop_lvl2[7] = g_prop[7] | (p_gen[7] & p_gen[6] & g_prop[5]);

    // 第三级群组传播计算
    wire [7:0] g_prop_lvl3;
    assign g_prop_lvl3[3:0] = g_prop_lvl2[3:0];
    assign g_prop_lvl3[4] = g_prop_lvl2[4];
    assign g_prop_lvl3[5] = g_prop_lvl2[5];
    assign g_prop_lvl3[6] = g_prop_lvl2[6];
    assign g_prop_lvl3[7] = g_prop_lvl2[7] | (p_gen[7] & p_gen[6] & p_gen[5] & p_gen[4] & g_prop_lvl2[3]);

    // 计算所有位的进位
    assign carry[0] = 1'b0; // 初始进位为0
    assign carry[1] = g_prop_lvl3[0];
    assign carry[2] = g_prop_lvl3[1];
    assign carry[3] = g_prop_lvl3[2];
    assign carry[4] = g_prop_lvl3[3];
    assign carry[5] = g_prop_lvl3[4];
    assign carry[6] = g_prop_lvl3[5];
    assign carry[7] = g_prop_lvl3[6];

    // 计算最终和
    assign next_cnt = p_gen ^ carry;
    
    // 第一级流水线: 计数器和输入捕获
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 8'h0;
            period_stage1 <= 8'h0;
            mode_stage1 <= MODE[1:0]; // 捕获模式参数
            valid_stage1 <= 1'b0;
        end else begin
            cnt_stage1 <= next_cnt;
            period_stage1 <= period;
            mode_stage1 <= MODE[1:0];
            valid_stage1 <= 1'b1;
        end
    end
    
    // 第二级流水线: 执行比较操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage2 <= 8'h0;
            period_stage2 <= 8'h0;
            mode_stage2 <= 2'b0;
            valid_stage2 <= 1'b0;
            compare_result_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            cnt_stage2 <= cnt_stage1;
            period_stage2 <= period_stage1;
            mode_stage2 <= mode_stage1;
            valid_stage2 <= valid_stage1;
            
            // 比较逻辑 - 在流水线第二级
            case(mode_stage1)
                2'b00: compare_result_stage2 <= (cnt_stage1 == (period_stage1 - 8'h1));  // 单次触发模式
                2'b01: begin  // 持续高电平模式
                    if (cnt_stage1 == 8'hFF) begin
                        compare_result_stage2 <= (8'h0 >= period_stage1);
                    end else begin
                        compare_result_stage2 <= (cnt_stage1 >= period_stage1);
                    end
                end
                2'b10: compare_result_stage2 <= (cnt_stage1[3:0] == period_stage1[3:0]);  // 分频模式
                default: compare_result_stage2 <= 1'b0;
            endcase
        end
    end
    
    // 输出阶段: 最终确定输出信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else if (valid_stage2) begin
            out <= compare_result_stage2;
        end
    end
endmodule