//SystemVerilog
// 顶层模块
module shadow_reg_comb_out #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  en,
    input  [WIDTH-1:0]     din,
    output [WIDTH-1:0]     dout
);
    // 内部信号
    wire [WIDTH-1:0] shadow_data;
    
    // 实例化数据寄存器子模块
    data_register #(
        .WIDTH(WIDTH)
    ) register_inst (
        .clk        (clk),
        .en         (en),
        .din        (din),
        .shadow_data(shadow_data)
    );
    
    // 实例化输出处理子模块
    output_handler #(
        .WIDTH(WIDTH)
    ) output_inst (
        .shadow_data(shadow_data),
        .dout       (dout)
    );
    
endmodule

// 数据寄存器子模块 - 负责数据存储功能
module data_register #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  en,
    input      [WIDTH-1:0] din,
    output reg [WIDTH-1:0] shadow_data
);
    // 时序逻辑，仅在使能有效时更新数据
    always @(posedge clk) begin
        if (en) begin
            shadow_data <= din;
        end
    end
endmodule

// 输出处理子模块 - 负责驱动输出信号
module output_handler #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] shadow_data,
    output [WIDTH-1:0] dout
);
    // 组合逻辑，将寄存器数据直接连接到输出
    assign dout = shadow_data;
endmodule