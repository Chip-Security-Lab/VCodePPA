//SystemVerilog
module sync_weighted_avg #(
    parameter DW = 12,
    parameter WEIGHTS = 3
)(
    input clk, rstn,
    input [DW-1:0] sample_in,
    input [7:0] weights [WEIGHTS-1:0],
    output reg [DW-1:0] filtered_out
);
    reg [DW-1:0] samples [WEIGHTS-1:0];
    reg [DW+8-1:0] weighted_sum_r;
    reg [7:0] weight_sum_r;
    wire [DW+8-1:0] weighted_sum;
    wire [7:0] weight_sum;
    wire [DW-1:0] division_result;
    integer i;
    
    // 计算加权和和权重和的组合逻辑
    assign weighted_sum = weighted_sum_r;
    assign weight_sum = weight_sum_r;
    
    // 归一化除法的组合逻辑
    assign division_result = weighted_sum / weight_sum;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < WEIGHTS; i = i + 1)
                samples[i] <= 0;
            weighted_sum_r <= 0;
            weight_sum_r <= 0;
            filtered_out <= 0;
        end else begin
            // 移动样本通过延迟线
            for (i = WEIGHTS-1; i > 0; i = i - 1)
                samples[i] <= samples[i-1];
            samples[0] <= sample_in;
            
            // 计算加权和和权重和
            weighted_sum_r <= 0;
            weight_sum_r <= 0;
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                weighted_sum_r <= weighted_sum_r + samples[i] * weights[i];
                weight_sum_r <= weight_sum_r + weights[i];
            end
            
            // 将除法结果直接寄存到输出
            filtered_out <= division_result;
        end
    end
endmodule