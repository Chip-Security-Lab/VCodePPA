//SystemVerilog
module universal_ff (
    input clk, rstn,
    input [1:0] mode,
    input d, j, k, t, s, r,
    output reg q
);
    // 流水线第一阶段 - 数据准备
    reg [1:0] mode_stage1;
    reg d_stage1, j_stage1, k_stage1, t_stage1, s_stage1, r_stage1, q_stage1;
    reg valid_stage1;
    
    // 流水线第二阶段 - 逻辑计算中间结果
    reg [1:0] mode_stage2;
    reg calc_result_stage2;
    reg valid_stage2;
    
    // 第一级流水线 - 模式寄存器
    always @(posedge clk) begin
        if (!rstn)
            mode_stage1 <= 2'b00;
        else
            mode_stage1 <= mode;
    end
    
    // 第一级流水线 - D触发器输入
    always @(posedge clk) begin
        if (!rstn)
            d_stage1 <= 1'b0;
        else
            d_stage1 <= d;
    end
    
    // 第一级流水线 - JK触发器输入
    always @(posedge clk) begin
        if (!rstn) begin
            j_stage1 <= 1'b0;
            k_stage1 <= 1'b0;
        end else begin
            j_stage1 <= j;
            k_stage1 <= k;
        end
    end
    
    // 第一级流水线 - T触发器输入
    always @(posedge clk) begin
        if (!rstn)
            t_stage1 <= 1'b0;
        else
            t_stage1 <= t;
    end
    
    // 第一级流水线 - SR触发器输入
    always @(posedge clk) begin
        if (!rstn) begin
            s_stage1 <= 1'b0;
            r_stage1 <= 1'b0;
        end else begin
            s_stage1 <= s;
            r_stage1 <= r;
        end
    end
    
    // 第一级流水线 - 当前输出反馈
    always @(posedge clk) begin
        if (!rstn)
            q_stage1 <= 1'b0;
        else
            q_stage1 <= q;
    end
    
    // 第一级流水线 - 有效信号生成
    always @(posedge clk) begin
        if (!rstn)
            valid_stage1 <= 1'b0;
        else
            valid_stage1 <= 1'b1;
    end
    
    // 第二级流水线 - 模式传递
    always @(posedge clk) begin
        if (!rstn)
            mode_stage2 <= 2'b00;
        else if (valid_stage1)
            mode_stage2 <= mode_stage1;
    end
    
    // 第二级流水线 - 有效信号传递
    always @(posedge clk) begin
        if (!rstn)
            valid_stage2 <= 1'b0;
        else
            valid_stage2 <= valid_stage1;
    end
    
    // 第二级流水线 - D模式逻辑计算
    reg d_result;
    always @(*) begin
        d_result = d_stage1;
    end
    
    // 第二级流水线 - JK模式逻辑计算
    reg jk_result;
    always @(*) begin
        jk_result = j_stage1 & ~q_stage1 | ~k_stage1 & q_stage1;
    end
    
    // 第二级流水线 - T模式逻辑计算
    reg t_result;
    always @(*) begin
        t_result = t_stage1 ^ q_stage1;
    end
    
    // 第二级流水线 - SR模式逻辑计算
    reg sr_result;
    always @(*) begin
        sr_result = s_stage1 | (~r_stage1 & q_stage1);
    end
    
    // 第二级流水线 - 逻辑计算结果选择
    always @(posedge clk) begin
        if (!rstn) begin
            calc_result_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            case(mode_stage1)
                2'b00: calc_result_stage2 <= d_result;    // D模式
                2'b01: calc_result_stage2 <= jk_result;   // JK模式
                2'b10: calc_result_stage2 <= t_result;    // T模式
                2'b11: calc_result_stage2 <= sr_result;   // SR模式
            endcase
        end
    end
    
    // 最终阶段 - 输出寄存器更新
    always @(posedge clk) begin
        if (!rstn)
            q <= 1'b0;
        else if (valid_stage2)
            q <= calc_result_stage2;
    end
endmodule