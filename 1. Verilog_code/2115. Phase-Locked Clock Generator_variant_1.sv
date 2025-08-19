//SystemVerilog
module phase_locked_clk(
    input ref_clk,
    input target_clk,
    input rst,
    output reg clk_out,
    output reg locked
);
    // 流水线阶段信号 - 增加额外的流水线级
    reg [1:0] phase_state_stage1, phase_state_stage2, phase_state_stage3;
    reg ref_detect_stage1, ref_detect_stage2, ref_detect_stage3;
    reg target_detect_stage1, target_detect_stage2, target_detect_stage3;
    
    // 流水线控制信号 - 增加额外的流水线级
    reg valid_stage1, valid_stage2, valid_stage3;
    reg locked_stage1, locked_stage2;
    reg clk_toggle, clk_toggle_next;
    
    // 切割长路径中间信号
    reg [1:0] phase_state_next;
    reg locked_next;
    
    // 阶段1: 参考时钟检测
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            ref_detect_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            ref_detect_stage1 <= 1'b1;
            valid_stage1 <= 1'b1;
        end
    end
    
    // 阶段1: 目标时钟检测同步
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            target_detect_stage1 <= 1'b0;
        end else begin
            target_detect_stage1 <= target_detect_stage3;
        end
    end
    
    // 阶段1: 相位状态计算 - 切割关键路径
    always @(*) begin
        if (target_detect_stage1) begin
            phase_state_next = 2'b00;
            locked_next = 1'b1;
        end else begin
            phase_state_next = phase_state_stage1 + 1;
            locked_next = (phase_state_stage1 == 2'b00);
        end
    end
    
    // 阶段1: 相位状态寄存更新
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            phase_state_stage1 <= 2'b00;
            locked_stage1 <= 1'b0;
        end else begin
            phase_state_stage1 <= phase_state_next;
            locked_stage1 <= locked_next;
        end
    end
    
    // 阶段2: 流水线寄存器更新
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            phase_state_stage2 <= 2'b00;
            ref_detect_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            locked_stage2 <= 1'b0;
        end else begin
            phase_state_stage2 <= phase_state_stage1;
            ref_detect_stage2 <= ref_detect_stage1;
            valid_stage2 <= valid_stage1;
            locked_stage2 <= locked_stage1;
        end
    end
    
    // 阶段3: 额外流水线寄存器更新
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            phase_state_stage3 <= 2'b00;
            ref_detect_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            phase_state_stage3 <= phase_state_stage2;
            ref_detect_stage3 <= ref_detect_stage2;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 锁定状态输出 - 使用流水线阶段2
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            locked <= 1'b0;
        end else if (valid_stage2) begin
            locked <= locked_stage2;
        end
    end
    
    // 时钟切换逻辑 - 切割关键路径
    always @(*) begin
        clk_toggle_next = valid_stage2 && (phase_state_stage2 == 2'b00) ? ~clk_toggle : clk_toggle;
    end
    
    // 时钟生成控制 - 分离组合逻辑和时序逻辑
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            clk_toggle <= 1'b0;
        end else begin
            clk_toggle <= clk_toggle_next;
        end
    end
    
    // 时钟输出生成 - 减少输出路径的组合逻辑
    always @(posedge ref_clk or posedge rst) begin
        if (rst) begin
            clk_out <= 1'b0;
        end else begin
            clk_out <= (valid_stage2 && phase_state_stage2 == 2'b00) ? ~clk_out : clk_out;
        end
    end
    
    // 目标时钟检测流水线
    always @(posedge target_clk or posedge rst) begin
        if (rst) begin
            target_detect_stage2 <= 1'b0;
        end else begin
            target_detect_stage2 <= ref_detect_stage3;
        end
    end
    
    // 额外的时钟域同步
    always @(posedge target_clk or posedge rst) begin
        if (rst) begin
            target_detect_stage3 <= 1'b0;
        end else begin
            target_detect_stage3 <= target_detect_stage2;
        end
    end
endmodule