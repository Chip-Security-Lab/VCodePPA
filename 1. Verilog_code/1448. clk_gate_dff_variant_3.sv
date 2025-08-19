//SystemVerilog
module clk_gate_dff (
    input wire clk,
    input wire en,
    input wire d,
    output reg q
);
    // 流水线阶段1: 使能信号寄存
    reg en_stage1;
    
    // 流水线阶段2: 数据预处理寄存
    reg d_stage2;
    wire valid_stage2;
    
    // 流水线阶段3: 输出寄存
    reg valid_stage3;
    wire gated_clk;
    
    // 流水线控制信号
    reg pipeline_active;
    
    // 阶段1: 使能信号处理和寄存
    always @(posedge clk) begin
        en_stage1 <= en;
        pipeline_active <= 1'b1; // 流水线启动逻辑
    end
    
    // 生成门控时钟
    assign gated_clk = clk & en_stage1;
    assign valid_stage2 = pipeline_active & en_stage1;
    
    // 阶段2: 数据预处理阶段
    always @(posedge clk) begin
        if (valid_stage2) begin
            d_stage2 <= d;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 阶段3: 输出阶段
    always @(posedge gated_clk) begin
        if (valid_stage3) begin
            q <= d_stage2;
        end
    end
endmodule