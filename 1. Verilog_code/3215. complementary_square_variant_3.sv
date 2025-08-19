//SystemVerilog
module complementary_square(
    input i_clk,
    input i_rst_n,
    input [7:0] i_period,
    input [7:0] i_phase,
    output o_wave,
    output o_wave_n
);

    // 内部信号声明
    reg [7:0] counter_stage1, counter_stage2;
    reg out_reg;
    reg [7:0] period_reg_stage1, period_reg_stage2;
    reg [7:0] phase_reg_stage1, phase_reg_stage2;
    reg [7:0] period_minus_one_stage1, period_minus_one_stage2, period_minus_one_stage3;
    
    // 流水线控制信号
    reg counter_reset_stage1, counter_reset_stage2, counter_reset_stage3;
    reg phase_match_stage1, phase_match_stage2, phase_match_stage3;
    
    // 输入缓存阶段 - 流水线第一级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            period_reg_stage1 <= 8'd0;
            phase_reg_stage1 <= 8'd0;
        end else begin
            period_reg_stage1 <= i_period;
            phase_reg_stage1 <= i_phase;
        end
    end

    // 输入缓存阶段 - 流水线第二级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            period_reg_stage2 <= 8'd0;
            phase_reg_stage2 <= 8'd0;
        end else begin
            period_reg_stage2 <= period_reg_stage1;
            phase_reg_stage2 <= phase_reg_stage1;
        end
    end

    // 周期减1计算 - 流水线第一级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            period_minus_one_stage1 <= 8'd0;
        end else begin
            period_minus_one_stage1 <= period_reg_stage1 - 8'd1;
        end
    end

    // 周期减1计算 - 流水线第二级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            period_minus_one_stage2 <= 8'd0;
        end else begin
            period_minus_one_stage2 <= period_minus_one_stage1;
        end
    end

    // 周期减1计算 - 流水线第三级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            period_minus_one_stage3 <= 8'd0;
        end else begin
            period_minus_one_stage3 <= period_minus_one_stage2;
        end
    end

    // 计数器控制逻辑 - 流水线第一级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_reset_stage1 <= 1'b0;
        end else begin
            counter_reset_stage1 <= (counter_stage1 >= period_minus_one_stage2);
        end
    end

    // 计数器控制逻辑 - 流水线第二级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_reset_stage2 <= 1'b0;
            counter_reset_stage3 <= 1'b0;
        end else begin
            counter_reset_stage2 <= counter_reset_stage1;
            counter_reset_stage3 <= counter_reset_stage2;
        end
    end

    // 相位匹配检测 - 流水线第一级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            phase_match_stage1 <= 1'b0;
        end else begin
            phase_match_stage1 <= (counter_stage1 == phase_reg_stage2);
        end
    end

    // 相位匹配检测 - 流水线第二级和第三级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            phase_match_stage2 <= 1'b0;
            phase_match_stage3 <= 1'b0;
        end else begin
            phase_match_stage2 <= phase_match_stage1;
            phase_match_stage3 <= phase_match_stage2;
        end
    end

    // 计数器模块 - 第一级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_stage1 <= 8'd0;
        end else if (counter_reset_stage2) begin
            counter_stage1 <= 8'd0;
        end else begin
            counter_stage1 <= counter_stage1 + 8'd1;
        end
    end

    // 计数器模块 - 第二级
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            counter_stage2 <= 8'd0;
        end else begin
            counter_stage2 <= counter_stage1;
        end
    end

    // 输出波形生成模块
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            out_reg <= 1'b0;
        end else if (counter_reset_stage3) begin
            out_reg <= ~out_reg;
        end
    end

    // 输出分配
    assign o_wave = out_reg;
    assign o_wave_n = ~out_reg;

endmodule