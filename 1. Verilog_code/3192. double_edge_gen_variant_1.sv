//SystemVerilog
module double_edge_gen (
    input clk_in,
    input rst_n,
    output reg clk_out
);

reg clk_phase_stage1;
reg clk_phase_stage2;

// 第一级流水线 - 时钟相位生成
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_phase_stage1 <= 1'b0;
    else
        clk_phase_stage1 <= ~clk_phase_stage1;
end

// 第二级流水线 - 时钟相位传递
always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_phase_stage2 <= 1'b0;
    else
        clk_phase_stage2 <= clk_phase_stage1;
end

// 输出级 - 在时钟下降沿采样相位值
always @(negedge clk_in or negedge rst_n) begin
    if (!rst_n)
        clk_out <= 1'b0;
    else
        clk_out <= clk_phase_stage2;
end

endmodule