//SystemVerilog
module ChainVotingRecovery #(parameter WIDTH=4, STAGES=5) (
    input clk,
    input [WIDTH-1:0] noisy_input,
    output reg [WIDTH-1:0] voted_output
);
    reg [WIDTH-1:0] delay_chain [0:STAGES-1];
    reg [WIDTH-1:0] stage1_sum [0:WIDTH-1]; // 第一级流水线寄存器-各位的求和结果
    reg [WIDTH:0] threshold_reg;            // 阈值寄存器
    reg [WIDTH-1:0] borrow_stage1;          // 第一级流水线寄存器-借位信号
    reg [WIDTH-1:0] comparison_result;      // 最终比较结果
    integer i;

    // 设置阈值为STAGES/2
    wire [WIDTH:0] threshold = STAGES/2;

    always @(posedge clk) begin
        // 移位寄存器逻辑
        for (i = STAGES-1; i > 0; i = i - 1) begin
            delay_chain[i] <= delay_chain[i-1];
        end
        delay_chain[0] <= noisy_input;
        
        // 第一阶段流水线 - 计算每一位的和并寄存阈值
        threshold_reg <= threshold;
        for (i = 0; i < WIDTH; i = i + 1) begin
            stage1_sum[i] <= delay_chain[0][i] + delay_chain[1][i] + delay_chain[2][i] + 
                           delay_chain[3][i] + delay_chain[4][i];
        end
        
        // 第二阶段流水线 - 计算借位信号
        borrow_stage1[0] <= (stage1_sum[0] < threshold_reg[0]);
        for (i = 1; i < WIDTH; i = i + 1) begin
            borrow_stage1[i] <= (stage1_sum[i] < threshold_reg[i]) || 
                              ((stage1_sum[i] == threshold_reg[i]) && borrow_stage1[i-1]);
        end
        
        // 第三阶段流水线 - 计算比较结果
        for (i = 0; i < WIDTH; i = i + 1) begin
            comparison_result[i] <= ~borrow_stage1[i];
        end
        
        // 第四阶段流水线 - 最终输出
        voted_output <= comparison_result;
    end
endmodule