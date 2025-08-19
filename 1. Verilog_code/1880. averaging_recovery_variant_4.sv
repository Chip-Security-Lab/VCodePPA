//SystemVerilog
module averaging_recovery #(
    parameter WIDTH = 8,
    parameter AVG_DEPTH = 4
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] noisy_in,
    input wire sample_en,
    output reg [WIDTH-1:0] filtered_out
);
    // 寄存输入信号
    reg [WIDTH-1:0] noisy_in_reg;
    reg sample_en_reg;
    
    // 样本存储
    reg [WIDTH-1:0] samples [0:AVG_DEPTH-2];  // 减少一个存储单元
    reg [WIDTH+2:0] sum;
    integer i;
    
    // 寄存输入信号 - 前向重定时
    always @(posedge clk) begin
        if (rst) begin
            noisy_in_reg <= 0;
            sample_en_reg <= 0;
        end else begin
            noisy_in_reg <= noisy_in;
            sample_en_reg <= sample_en;
        end
    end
    
    // 优化的样本移位寄存器管理
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < AVG_DEPTH-1; i = i + 1)
                samples[i] <= 0;
            sum <= 0;
        end else if (sample_en_reg) begin
            // 计算新的总和并同时执行移位
            sum <= noisy_in_reg;
            for (i = 0; i < AVG_DEPTH-2; i = i + 1) begin
                samples[i] <= samples[i+1];
                sum <= sum + samples[i+1];
            end
            samples[AVG_DEPTH-2] <= noisy_in_reg;
            sum <= sum + noisy_in_reg;
        end
    end
    
    // 计算平均值
    always @(posedge clk) begin
        if (rst) begin
            filtered_out <= 0;
        end else if (sample_en_reg) begin
            filtered_out <= sum / AVG_DEPTH;
        end
    end
endmodule