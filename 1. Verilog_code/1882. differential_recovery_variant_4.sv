//SystemVerilog
// IEEE 1364-2005 Verilog
module differential_recovery (
    input wire clk,
    input wire [7:0] pos_signal,
    input wire [7:0] neg_signal,
    output reg [8:0] recovered_signal
);
    // 寄存器化输入信号
    reg [7:0] pos_signal_reg;
    reg [7:0] neg_signal_reg;
    
    // 比较结果中间寄存器
    reg pos_greater_eq_stage1;
    reg pos_greater_eq_stage2;
    
    // 差值计算中间寄存器
    reg [7:0] pos_minus_neg;
    reg [7:0] neg_minus_pos;
    reg [7:0] selected_diff;
    
    always @(posedge clk) begin
        // 第一级寄存器：缓存输入信号
        pos_signal_reg <= pos_signal;
        neg_signal_reg <= neg_signal;
        
        // 第二级：预先计算两种可能的差值，减少关键路径延迟
        pos_greater_eq_stage1 <= (pos_signal_reg >= neg_signal_reg);
        pos_minus_neg <= pos_signal_reg - neg_signal_reg;
        neg_minus_pos <= neg_signal_reg - pos_signal_reg;
        
        // 第三级：基于比较结果选择正确的差值
        pos_greater_eq_stage2 <= pos_greater_eq_stage1;
        selected_diff <= pos_greater_eq_stage1 ? pos_minus_neg : neg_minus_pos;
        
        // 最终输出
        recovered_signal <= {~pos_greater_eq_stage2, selected_diff};
    end
endmodule