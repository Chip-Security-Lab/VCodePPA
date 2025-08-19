//SystemVerilog
module param_signal_recovery #(
    parameter SIGNAL_WIDTH = 12,
    parameter THRESHOLD = 2048,  // 使用十进制值替代SIGNAL_WIDTH'h800
    parameter NOISE_MARGIN = 256 // 使用十进制值替代SIGNAL_WIDTH'h100
)(
    input wire sample_clk,
    input wire [SIGNAL_WIDTH-1:0] input_signal,
    output reg [SIGNAL_WIDTH-1:0] recovered_signal
);
    // 计算阈值下限和上限，减少组合逻辑链长度
    wire [SIGNAL_WIDTH-1:0] threshold_lower = THRESHOLD - NOISE_MARGIN;
    wire [SIGNAL_WIDTH-1:0] threshold_upper = THRESHOLD + NOISE_MARGIN;
    
    // 流水线寄存器，第一级
    reg [SIGNAL_WIDTH-1:0] input_signal_reg;
    reg [SIGNAL_WIDTH-1:0] threshold_lower_reg, threshold_upper_reg;
    
    // 流水线寄存器，第二级
    reg comp_lower_result, comp_upper_result;
    reg [SIGNAL_WIDTH-1:0] input_signal_reg2;
    
    // 信号有效判断，第三级
    reg valid_signal_reg;
    reg [SIGNAL_WIDTH-1:0] input_signal_reg3;
    
    always @(posedge sample_clk) begin
        // 第一级流水线
        input_signal_reg <= input_signal;
        threshold_lower_reg <= threshold_lower;
        threshold_upper_reg <= threshold_upper;
        
        // 第二级流水线 - 分解比较操作
        comp_lower_result <= (input_signal_reg > threshold_lower_reg);
        comp_upper_result <= (input_signal_reg < threshold_upper_reg);
        input_signal_reg2 <= input_signal_reg;
        
        // 第三级流水线 - 合并比较结果
        valid_signal_reg <= comp_lower_result && comp_upper_result;
        input_signal_reg3 <= input_signal_reg2;
        
        // 输出阶段
        recovered_signal <= valid_signal_reg ? input_signal_reg3 : recovered_signal;
    end
endmodule