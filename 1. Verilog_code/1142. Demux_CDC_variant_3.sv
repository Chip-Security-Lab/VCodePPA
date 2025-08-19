//SystemVerilog
//IEEE 1364-2005 Verilog
module Demux_CDC #(parameter DW=8) (
    input clk_a, clk_b,
    input [DW-1:0] data_a,
    input sel_a,
    output reg [DW-1:0] data_b0,
    output reg [DW-1:0] data_b1
);
    // 内部寄存器，用于时钟域同步
    reg [DW-1:0] sync0, sync1;
    // 缓存数据和取反值
    wire [DW-1:0] neg_data_a;
    
    // 使用直接的计算代替查找表
    assign neg_data_a = ~data_a + 1'b1; // 2的补码，更高效
    
    // 时钟域A的逻辑 - 使用三目运算符优化条件逻辑
    always @(posedge clk_a) begin
        sync0 <= sel_a ? data_a : neg_data_a;
        sync1 <= sel_a ? neg_data_a : data_a;
    end
    
    // 时钟域B的逻辑 - 保持不变
    always @(posedge clk_b) begin
        data_b0 <= sync0;
        data_b1 <= sync1;
    end
endmodule