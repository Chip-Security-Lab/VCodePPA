//SystemVerilog
module RangeDetector_CDC #(
    parameter WIDTH = 8
)(
    input src_clk,
    input dst_clk,
    input rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg flag_out
);

reg [WIDTH-1:0] src_data;
reg src_flag, meta_flag, dst_flag;
reg [WIDTH-1:0] threshold_reg;
reg comp_result;

// 源时钟域 - 寄存器前移
always @(posedge src_clk) begin
    src_data <= data_in;
    threshold_reg <= threshold;
    comp_result <= (data_in > threshold);
    src_flag <= comp_result;
end

// 同步器链 - 使用条件运算符优化时序
always @(posedge dst_clk or negedge rst_n) begin
    meta_flag <= !rst_n ? 1'b0 : src_flag;
    dst_flag <= !rst_n ? 1'b0 : meta_flag;
    flag_out <= !rst_n ? 1'b0 : dst_flag;
end

endmodule