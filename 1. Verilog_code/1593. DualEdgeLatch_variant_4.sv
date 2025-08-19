//SystemVerilog
module DualEdgeLatch #(parameter DW=16) (
    input clk,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

    // 上升沿触发器
    reg [DW-1:0] pos_edge_ff;
    always @(posedge clk) begin
        pos_edge_ff <= din;
    end

    // 下降沿触发器
    reg [DW-1:0] neg_edge_ff;
    always @(negedge clk) begin
        neg_edge_ff <= din;
    end

    // 优化后的输出选择逻辑
    wire [DW-1:0] pos_mux = {DW{clk}} & pos_edge_ff;
    wire [DW-1:0] neg_mux = {DW{~clk}} & neg_edge_ff;
    assign dout = pos_mux | neg_mux;

endmodule