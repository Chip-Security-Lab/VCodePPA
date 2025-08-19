//SystemVerilog
module glitch_free_clock_gate (
    input  wire clk_in,
    input  wire enable,
    input  wire rst_n,
    output wire clk_out
);
    // 增加流水线级数，从2级扩展到4级
    reg enable_stage1, enable_stage2, enable_stage3, enable_stage4;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
    reg [3:0] enable_pipeline;
    
    // 细分时钟门控控制逻辑
    reg clk_gate_active;
    reg next_clk_gate_active;
    reg pre_gate_status;
    
    // 计算下一个时钟周期的门控状态 - 拆分为更简单的逻辑
    always @(*) begin
        pre_gate_status = valid_stage3 ? enable_stage3 : clk_gate_active;
        next_clk_gate_active = valid_stage4 ? enable_stage4 : pre_gate_status;
    end
    
    // 第一级流水线
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            enable_pipeline[0] <= 1'b0;
        end else begin
            enable_stage1 <= enable;
            valid_stage1 <= 1'b1;
            enable_pipeline[0] <= enable;
        end
    end
    
    // 第二级流水线
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            enable_pipeline[1] <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
            valid_stage2 <= valid_stage1;
            enable_pipeline[1] <= enable_pipeline[0];
        end
    end
    
    // 第三级流水线
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
            enable_pipeline[2] <= 1'b0;
        end else begin
            enable_stage3 <= enable_stage2;
            valid_stage3 <= valid_stage2;
            enable_pipeline[2] <= enable_pipeline[1];
        end
    end
    
    // 第四级流水线
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage4 <= 1'b0;
            valid_stage4 <= 1'b0;
            enable_pipeline[3] <= 1'b0;
            clk_gate_active <= 1'b0;
        end else begin
            enable_stage4 <= enable_stage3;
            valid_stage4 <= valid_stage3;
            enable_pipeline[3] <= enable_pipeline[2];
            clk_gate_active <= next_clk_gate_active;
        end
    end
    
    // 优化的时钟输出逻辑 - 减少关键路径
    // 使用最终阶段的状态进行门控
    wire gating_control = clk_gate_active;
    
    // 时钟输出
    assign clk_out = clk_in & gating_control;
endmodule