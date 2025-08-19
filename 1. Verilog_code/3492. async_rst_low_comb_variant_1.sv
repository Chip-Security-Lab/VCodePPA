//SystemVerilog
// 顶层模块
module async_rst_low_comb #(
    parameter WIDTH = 16
)(
    input  wire rst_n,
    input  wire [WIDTH-1:0] in_data,
    output wire [WIDTH-1:0] out_data
);

    // 内部信号
    wire [WIDTH-1:0] reset_mask;
    wire [WIDTH-1:0] masked_data;

    // 实例化子模块
    reset_controller #(
        .WIDTH(WIDTH)
    ) u_reset_controller (
        .rst_n      (rst_n),
        .reset_mask (reset_mask)
    );

    data_handler #(
        .WIDTH(WIDTH)
    ) u_data_handler (
        .in_data    (in_data),
        .reset_mask (reset_mask),
        .out_data   (out_data)
    );

endmodule

// 复位控制子模块
module reset_controller #(
    parameter WIDTH = 16
)(
    input  wire rst_n,
    output reg  [WIDTH-1:0] reset_mask
);

    always @(*) begin
        reset_mask = rst_n ? {WIDTH{1'b1}} : {WIDTH{1'b0}};
    end

endmodule

// 数据处理子模块
module data_handler #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] in_data,
    input  wire [WIDTH-1:0] reset_mask,
    output wire [WIDTH-1:0] out_data
);

    assign out_data = in_data & reset_mask;

endmodule