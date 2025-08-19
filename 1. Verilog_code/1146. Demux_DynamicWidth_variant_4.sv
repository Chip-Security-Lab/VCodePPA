//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------
// 顶层模块: 动态宽度解复用器
//-----------------------------------------------------------------------------
module Demux_DynamicWidth #(
    parameter MAX_DW = 32
)(
    input                    clk,
    input [5:0]              width_config,
    input [MAX_DW-1:0]       data_in,
    output [3:0][MAX_DW-1:0] data_out
);

    // 内部连线
    wire [MAX_DW-1:0] mask;
    
    // 实例化掩码生成器子模块
    MaskGenerator #(
        .MAX_DW(MAX_DW)
    ) mask_gen_inst (
        .width_config(width_config),
        .mask(mask)
    );
    
    // 实例化数据处理器子模块
    DataProcessor #(
        .MAX_DW(MAX_DW)
    ) data_proc_inst (
        .clk(clk),
        .data_in(data_in),
        .mask(mask),
        .data_out(data_out)
    );

endmodule

//-----------------------------------------------------------------------------
// 子模块: 掩码生成器 - 根据配置宽度生成适当的掩码
//-----------------------------------------------------------------------------
module MaskGenerator #(
    parameter MAX_DW = 32
)(
    input [5:0]        width_config,
    output [MAX_DW-1:0] mask
);

    // 组合逻辑生成掩码，实现 (1 << width_config) - 1
    assign mask = (1'b1 << width_config) - 1'b1;

endmodule

//-----------------------------------------------------------------------------
// 子模块: 数据处理器 - 应用掩码并产生输出数据
//-----------------------------------------------------------------------------
module DataProcessor #(
    parameter MAX_DW = 32
)(
    input                    clk,
    input [MAX_DW-1:0]       data_in,
    input [MAX_DW-1:0]       mask,
    output reg [3:0][MAX_DW-1:0] data_out
);

    // 同步处理数据输出
    always @(posedge clk) begin
        data_out[0] <= data_in & mask;        // 掩码位为1的数据
        data_out[1] <= data_in & ~mask;       // 掩码位为0的数据
        data_out[2] <= 0;                     // 预留未来功能扩展
        data_out[3] <= 0;                     // 预留未来功能扩展
    end

endmodule