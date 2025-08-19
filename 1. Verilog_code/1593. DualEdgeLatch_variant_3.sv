//SystemVerilog
module DualEdgeLatch #(parameter DW=16) (
    input clk, 
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    // 内部信号声明
    wire [DW-1:0] rising_dout;
    wire [DW-1:0] falling_dout;
    
    // 实例化上升沿锁存器
    RisingEdgeLatch #(.DW(DW)) rising_edge_latch (
        .clk(clk),
        .din(din),
        .dout(rising_dout)
    );
    
    // 实例化下降沿锁存器
    FallingEdgeLatch #(.DW(DW)) falling_edge_latch (
        .clk(clk),
        .din(din),
        .dout(falling_dout)
    );
    
    // 实例化输出选择器
    OutputSelector #(.DW(DW)) output_selector (
        .clk(clk),
        .rising_dout(rising_dout),
        .falling_dout(falling_dout),
        .dout(dout)
    );
endmodule

module RisingEdgeLatch #(parameter DW=16) (
    input clk,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(posedge clk) begin
        dout <= din;
    end
endmodule

module FallingEdgeLatch #(parameter DW=16) (
    input clk,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    always @(negedge clk) begin
        dout <= din;
    end
endmodule

module OutputSelector #(parameter DW=16) (
    input clk,
    input [DW-1:0] rising_dout,
    input [DW-1:0] falling_dout,
    output reg [DW-1:0] dout
);
    always @(clk) begin
        dout <= clk ? rising_dout : falling_dout;
    end
endmodule