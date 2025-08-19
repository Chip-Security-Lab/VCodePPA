//SystemVerilog
// 顶层模块
module mux_async_rst #(
    parameter WIDTH = 8
)(
    input wire rst,
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output wire [WIDTH-1:0] data_out
);
    // 内部连线
    wire [WIDTH-1:0] mux_out;
    
    // 子模块实例化
    mux_selector #(
        .WIDTH(WIDTH)
    ) u_mux_selector (
        .sel(sel),
        .data_a(data_a),
        .data_b(data_b),
        .mux_out(mux_out)
    );
    
    reset_handler #(
        .WIDTH(WIDTH)
    ) u_reset_handler (
        .rst(rst),
        .data_in(mux_out),
        .data_out(data_out)
    );
    
endmodule

// 多路选择器子模块
module mux_selector #(
    parameter WIDTH = 8
)(
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output reg [WIDTH-1:0] mux_out
);
    always @(*) begin
        if (sel) begin
            mux_out = data_a;
        end else begin
            mux_out = data_b;
        end
    end
endmodule

// 复位处理子模块
module reset_handler #(
    parameter WIDTH = 8
)(
    input wire rst,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        if (rst) begin
            data_out = {WIDTH{1'b0}};
        end else begin
            data_out = data_in;
        end
    end
endmodule