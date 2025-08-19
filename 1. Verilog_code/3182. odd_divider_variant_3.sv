//SystemVerilog
module odd_divider #(
    parameter N = 5
)(
    input clk,
    input rst,
    output clk_out
);
    // 将状态计数和时钟生成进行更细粒度的流水线处理
    reg [2:0] state_stage1;
    reg [2:0] state_stage2;
    reg [2:0] next_state_stage1;
    reg state_reset_stage1;
    
    reg phase_clk_stage1;
    reg phase_clk_stage2;
    reg phase_clk_stage3;
    reg phase_clk_neg_stage1;
    reg phase_clk_neg_stage2;
    
    // 阶段1: 计算下一状态
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            next_state_stage1 <= 0;
            state_reset_stage1 <= 1;
        end
        else begin
            next_state_stage1 <= (state_stage1 == N-1) ? 0 : state_stage1 + 1;
            state_reset_stage1 <= (state_stage1 == N-1);
        end
    end
    
    // 阶段2: 更新状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= 0;
        end
        else begin
            state_stage1 <= next_state_stage1;
        end
    end
    
    // 阶段3: 计算第一级相位时钟
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase_clk_stage1 <= 0;
            state_stage2 <= 0;
        end
        else begin
            state_stage2 <= state_stage1;
            phase_clk_stage1 <= (next_state_stage1 < (N>>1)) ? 1 : 0;
        end
    end
    
    // 阶段4: 计算第二级相位时钟
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase_clk_stage2 <= 0;
        end
        else begin
            phase_clk_stage2 <= phase_clk_stage1;
        end
    end
    
    // 阶段5: 计算第三级相位时钟
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase_clk_stage3 <= 0;
        end
        else begin
            phase_clk_stage3 <= phase_clk_stage2;
        end
    end
    
    // 负边沿时钟流水线阶段1
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            phase_clk_neg_stage1 <= 0;
        end
        else begin
            phase_clk_neg_stage1 <= phase_clk_stage3;
        end
    end
    
    // 负边沿时钟流水线阶段2
    always @(negedge clk or posedge rst) begin
        if (rst) begin
            phase_clk_neg_stage2 <= 0;
        end
        else begin
            phase_clk_neg_stage2 <= phase_clk_neg_stage1;
        end
    end
    
    // 输出逻辑
    assign clk_out = phase_clk_stage3 | phase_clk_neg_stage2;
endmodule