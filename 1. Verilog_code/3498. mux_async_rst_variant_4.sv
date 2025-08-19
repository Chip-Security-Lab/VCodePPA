//SystemVerilog
// 顶层模块
module mux_async_rst #(parameter WIDTH=8)(
    input wire rst,
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output wire [WIDTH-1:0] data_out
);
    // 复位控制信号
    wire [WIDTH-1:0] mux_output;
    
    // 实例化数据选择子模块
    data_selector #(
        .WIDTH(WIDTH)
    ) data_sel_inst (
        .sel(sel),
        .data_a(data_a),
        .data_b(data_b),
        .mux_output(mux_output)
    );
    
    // 实例化复位控制子模块
    reset_controller #(
        .WIDTH(WIDTH)
    ) rst_ctrl_inst (
        .rst(rst),
        .data_in(mux_output),
        .data_out(data_out)
    );
    
endmodule

// 数据选择子模块
module data_selector #(parameter WIDTH=8)(
    input wire sel,
    input wire [WIDTH-1:0] data_a, data_b,
    output reg [WIDTH-1:0] mux_output
);
    always @(*) begin
        if (sel) begin
            mux_output = data_a;
        end else begin
            mux_output = data_b;
        end
    end
endmodule

// 复位控制子模块
module reset_controller #(parameter WIDTH=8)(
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