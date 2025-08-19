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
    // 注册输入信号
    reg [WIDTH-1:0] noisy_in_reg;
    reg sample_en_reg;
    
    // 样本存储
    reg [WIDTH-1:0] samples [0:AVG_DEPTH-2]; // 减少一个存储单元
    reg [WIDTH+2:0] sum_reg;
    reg [WIDTH+2:0] next_sum;
    integer i;
    
    // 注册输入信号
    always @(posedge clk) begin
        if (rst) begin
            noisy_in_reg <= 0;
            sample_en_reg <= 0;
        end else begin
            noisy_in_reg <= noisy_in;
            sample_en_reg <= sample_en;
        end
    end
    
    // 计算下一个和值（组合逻辑）
    always @(*) begin
        next_sum = 0;
        for (i = 0; i < AVG_DEPTH-1; i = i + 1)
            next_sum = next_sum + samples[i];
        next_sum = next_sum + noisy_in_reg; // 直接使用当前输入
    end
    
    // 样本移位和求和存储
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < AVG_DEPTH-1; i = i + 1)
                samples[i] <= 0;
            sum_reg <= 0;
        end else if (sample_en_reg) begin
            // 移位操作
            for (i = AVG_DEPTH-2; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= noisy_in_reg;
            
            // 存储求和结果
            sum_reg <= next_sum;
        end
    end
    
    // 输出平均值
    always @(posedge clk) begin
        if (rst) begin
            filtered_out <= 0;
        end else if (sample_en_reg) begin
            filtered_out <= sum_reg / AVG_DEPTH;
        end
    end
endmodule