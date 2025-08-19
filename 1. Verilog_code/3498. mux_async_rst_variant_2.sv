//SystemVerilog
// 顶层模块
module mux_async_rst #(parameter WIDTH=8)(
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

// 数据选择子模块 - 使用补码加法实现减法操作
module mux_selector #(parameter WIDTH=8)(
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output reg [WIDTH-1:0] mux_out
);
    // 使用补码逻辑实现减法
    wire [WIDTH-1:0] data_b_inverted;
    wire [WIDTH-1:0] subtraction_result;
    
    // 对data_b取反加一实现补码
    assign data_b_inverted = ~data_b + 1'b1;
    
    // 通过加法实现减法: data_a - data_b = data_a + (~data_b + 1)
    assign subtraction_result = data_a + data_b_inverted;
    
    always @(*) begin
        mux_out = sel ? subtraction_result : data_b; // 当sel为1时执行减法操作，否则传递data_b
    end
endmodule

// 复位处理子模块
module reset_handler #(parameter WIDTH=8)(
    input wire rst,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(*) begin
        data_out = rst ? {WIDTH{1'b0}} : data_in;
    end
endmodule