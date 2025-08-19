//SystemVerilog
module async_interp_filter #(
    parameter DW = 10
)(
    input clk,
    input rst_n,
    input [DW-1:0] prev_sample,
    input [DW-1:0] next_sample,
    input [$clog2(DW)-1:0] frac,
    output reg [DW-1:0] interp_out
);

    reg [DW-1:0] diff_r;
    reg [DW-1:0] prev_sample_r;
    reg [$clog2(DW)-1:0] frac_r;
    reg [2*DW-1:0] scaled_diff_r;
    reg [DW-1:0] prev_sample_r2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_r <= 0;
            prev_sample_r <= 0;
            frac_r <= 0;
            scaled_diff_r <= 0;
            prev_sample_r2 <= 0;
            interp_out <= 0;
        end else begin
            // 阶段1: 计算样本差值并寄存
            diff_r <= next_sample - prev_sample;
            prev_sample_r <= prev_sample;
            frac_r <= frac;
            
            // 阶段2: 计算缩放差值并寄存
            scaled_diff_r <= diff_r * frac_r;
            prev_sample_r2 <= prev_sample_r;
            
            // 阶段3: 生成最终插值输出
            interp_out <= prev_sample_r2 + scaled_diff_r[2*DW-1:DW];
        end
    end

endmodule