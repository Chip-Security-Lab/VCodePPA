//SystemVerilog
module double_edge_gen (
    input clk_in,
    input rst_n,  // 添加复位信号以确保初始状态
    output reg clk_out
);

// 增加流水线级数的实现
reg clk_phase_stage1;
reg clk_phase_stage2;
reg clk_phase_stage3;

// 第一级流水线 - 捕获时钟相位变化
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_phase_stage1 <= 1'b0;
    end else begin
        clk_phase_stage1 <= ~clk_phase_stage1;
    end
end

// 第二级流水线 - 传递时钟相位信息
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_phase_stage2 <= 1'b0;
    end else begin
        clk_phase_stage2 <= clk_phase_stage1;
    end
end

// 第三级流水线 - 最终时钟相位处理
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_phase_stage3 <= 1'b0;
    end else begin
        clk_phase_stage3 <= clk_phase_stage2;
    end
end

// 输出逻辑 - 在时钟下降沿采样
reg clk_phase_neg_stage1;
reg clk_phase_neg_stage2;

always @(negedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_phase_neg_stage1 <= 1'b0;
    end else begin
        clk_phase_neg_stage1 <= clk_phase_stage3;
    end
end

always @(negedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        clk_phase_neg_stage2 <= 1'b0;
        clk_out <= 1'b0;
    end else begin
        clk_phase_neg_stage2 <= clk_phase_neg_stage1;
        clk_out <= clk_phase_neg_stage2;
    end
end

endmodule