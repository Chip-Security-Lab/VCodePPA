//SystemVerilog
module IIR_LPF #(parameter W=8, ALPHA=4) (
    input clk, rst_n,
    input [W-1:0] din,
    input valid_in,
    output reg [W-1:0] dout,
    output reg valid_out
);
    // 预计算常量，避免每个时钟周期重复计算
    localparam [7:0] INV_ALPHA = 8'd255 - ALPHA;
    
    // 定义流水线寄存器
    reg [W-1:0] din_stage1;
    reg [W-1:0] dout_feedback;
    reg [W+7:0] din_term_stage1;
    reg [W+7:0] dout_term_stage1;
    reg [W+7:0] sum_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // 重置所有流水线寄存器
            din_stage1 <= 0;
            dout_feedback <= 0;
            din_term_stage1 <= 0;
            dout_term_stage1 <= 0;
            sum_stage2 <= 0;
            dout <= 0;
            
            // 重置控制信号
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            valid_out <= 0;
        end else begin
            // 第一级流水线：输入采样和乘法计算
            din_stage1 <= din;
            dout_feedback <= dout;
            din_term_stage1 <= ALPHA * din;
            dout_term_stage1 <= INV_ALPHA * dout_feedback;
            valid_stage1 <= valid_in;
            
            // 第二级流水线：加法运算
            sum_stage2 <= din_term_stage1 + dout_term_stage1;
            valid_stage2 <= valid_stage1;
            
            // 第三级流水线：移位并输出
            dout <= sum_stage2 >> 8;
            valid_out <= valid_stage2;
        end
    end
endmodule