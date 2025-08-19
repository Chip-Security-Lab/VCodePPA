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
    // Sample registers
    reg [DW-1:0] samples [WEIGHTS-1:0];
    
    // Intermediate calculation registers
    reg [DW+8-1:0] weight_prod [WEIGHTS-1:0];
    reg [DW+8-1:0] weighted_sum;
    reg [7:0] weight_sum;
    
    // Pipeline registers for improved timing
    reg [DW+8-1:0] weighted_sum_pipe;
    reg [7:0] weight_sum_pipe;
    
    integer i;
    
    // 模块1: 样本移位寄存器管理
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                samples[i] <= 0;
            end
        end else begin
            // Shift samples through delay line (optimized indexing)
            samples[0] <= sample_in;
            for (i = 1; i < WEIGHTS; i = i + 1)
                samples[i] <= samples[i-1];
        end
    end
    
    // 模块2: 权重乘积计算
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                weight_prod[i] <= 0;
            end
        end else begin
            // Pre-calculate all weight products in parallel
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                weight_prod[i] <= samples[i] * weights[i];
            end
        end
    end
    
    // 模块3: 权重和计算
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            weighted_sum <= 0;
            weight_sum <= 0;
        end else begin
            // Calculate sums (one cycle after products)
            weighted_sum <= 0;
            weight_sum <= 0;
            for (i = 0; i < WEIGHTS; i = i + 1) begin
                weighted_sum <= weighted_sum + weight_prod[i];
                weight_sum <= weight_sum + weights[i];
            end
        end
    end
    
    // 模块4: 管道寄存器更新
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            weighted_sum_pipe <= 0;
            weight_sum_pipe <= 0;
        end else begin
            // Pipeline the division operation
            weighted_sum_pipe <= weighted_sum;
            weight_sum_pipe <= weight_sum;
        end
    end
    
    // 模块5: 输出计算（避免除零）
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            filtered_out <= 0;
        end else begin
            // Avoid division by zero with a conditional
            if (weight_sum_pipe != 0)
                filtered_out <= weighted_sum_pipe / weight_sum_pipe;
        end
    end
endmodule