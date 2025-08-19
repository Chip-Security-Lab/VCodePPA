//SystemVerilog
// 顶层模块
module int_ctrl_edge_detect #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] async_int,
    output wire [WIDTH-1:0] edge_out
);
    wire [WIDTH-1:0] sync_int;
    
    // 异步信号同步子模块实例化
    signal_synchronizer #(
        .WIDTH(WIDTH)
    ) sync_stage (
        .clk       (clk),
        .async_in  (async_int),
        .sync_out  (sync_int)
    );
    
    // 边沿检测子模块实例化
    edge_detector #(
        .WIDTH(WIDTH)
    ) edge_detect_stage (
        .clk        (clk),
        .signal_in  (sync_int),
        .signal_prev(async_int),
        .edge_out   (edge_out)
    );
    
endmodule

// 信号同步子模块
module signal_synchronizer #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] async_in,
    output reg  [WIDTH-1:0] sync_out
);
    
    always @(posedge clk) begin
        sync_out <= async_in;
    end
    
endmodule

// 边沿检测子模块
module edge_detector #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire [WIDTH-1:0] signal_in,
    input  wire [WIDTH-1:0] signal_prev,
    output reg  [WIDTH-1:0] edge_out
);
    
    always @(posedge clk) begin
        edge_out <= signal_prev & ~signal_in;
    end
    
endmodule