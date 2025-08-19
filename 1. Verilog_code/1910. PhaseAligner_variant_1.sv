//SystemVerilog
module PhaseAligner #(
    parameter PHASE_STEPS = 8
)(
    input wire clk_ref,
    input wire clk_data,
    output reg [7:0] aligned_data
);

    // 阶段1: 输入采样寄存器
    reg clk_ref_sampled;
    
    // 阶段2: 多相位采样缓冲区
    reg [7:0] phase_samples [0:PHASE_STEPS-1];
    
    // 阶段3: 相位检测信号
    reg phase_transition_detected;
    
    // 阶段4: 数据选择和对齐缓冲区
    reg [7:0] selected_phase_data;
    
    // 采样输入时钟参考
    always @(posedge clk_data) begin
        clk_ref_sampled <= clk_ref;
    end
    
    // 移位缓冲区管理 - 构建多相位采样数组
    integer i;
    always @(posedge clk_data) begin
        for (i = PHASE_STEPS-1; i > 0; i = i - 1) begin
            phase_samples[i] <= phase_samples[i-1];
        end
        phase_samples[0] <= clk_ref_sampled;
    end
    
    // 相位转换检测 - 检测首尾相位是否发生变化
    always @(posedge clk_data) begin
        phase_transition_detected <= phase_samples[0] ^ phase_samples[PHASE_STEPS-1];
    end
    
    // 相位数据选择 - 选择中间相位数据
    always @(posedge clk_data) begin
        selected_phase_data <= phase_samples[PHASE_STEPS/2];
    end
    
    // 数据对齐输出 - 根据相位检测结果更新输出
    always @(posedge clk_data) begin
        if (phase_transition_detected) begin
            aligned_data <= selected_phase_data;
        end
    end

endmodule