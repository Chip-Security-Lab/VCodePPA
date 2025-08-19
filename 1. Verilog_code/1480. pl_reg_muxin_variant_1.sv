//SystemVerilog - IEEE 1364-2005
// 顶层模块 - 使用后向重定时技术的寄存器多路选择器
module pl_reg_muxin #(
    parameter W = 4  // 数据宽度参数
) (
    input              clk,     // 时钟信号
    input              sel,     // 选择信号
    input      [W-1:0] d0,      // 数据输入0
    input      [W-1:0] d1,      // 数据输入1
    output     [W-1:0] q        // 寄存器输出
);
    // 内部信号定义
    wire [W-1:0] d0_registered;
    wire [W-1:0] d1_registered;
    wire sel_registered;

    // 输入寄存模块实例化
    input_register #(
        .WIDTH(W)
    ) d0_reg_inst (
        .clk(clk),
        .data_in(d0),
        .data_out(d0_registered)
    );

    input_register #(
        .WIDTH(W)
    ) d1_reg_inst (
        .clk(clk),
        .data_in(d1),
        .data_out(d1_registered)
    );

    input_register #(
        .WIDTH(1)
    ) sel_reg_inst (
        .clk(clk),
        .data_in(sel),
        .data_out(sel_registered)
    );

    // 多路选择器模块实例化
    output_mux #(
        .WIDTH(W)
    ) output_mux_inst (
        .sel(sel_registered),
        .data0(d0_registered),
        .data1(d1_registered),
        .mux_out(q)
    );

endmodule

// 输入寄存器子模块 - 用于对输入信号进行寄存
module input_register #(
    parameter WIDTH = 4  // 可配置数据宽度
) (
    input                      clk,      // 时钟信号
    input      [WIDTH-1:0]     data_in,  // 数据输入
    output reg [WIDTH-1:0]     data_out  // 寄存器输出
);
    // 时序逻辑实现寄存器功能
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// 输出多路选择器子模块 - 用于选择寄存后的输入
module output_mux #(
    parameter WIDTH = 4  // 可配置数据宽度
) (
    input                  sel,      // 选择信号
    input      [WIDTH-1:0] data0,    // 数据输入0
    input      [WIDTH-1:0] data1,    // 数据输入1
    output     [WIDTH-1:0] mux_out   // 多路选择器输出
);
    // 组合逻辑实现多路选择
    assign mux_out = sel ? data1 : data0;
endmodule