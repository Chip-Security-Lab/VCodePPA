//SystemVerilog
// 顶层模块：优化的D触发器，带同步复位
module d_ff_sync_reset #(
    parameter RESET_VALUE = 1'b0  // 参数化复位值
)(
    input  wire clk,     // 时钟输入
    input  wire rst,     // 复位信号
    input  wire d,       // 数据输入
    output wire q        // 数据输出
);
    // 内部信号
    wire reset_data;
    wire ff_out;
    
    // 子模块实例化
    input_stage input_ctrl (
        .rst(rst),
        .d(d),
        .reset_value(RESET_VALUE),
        .out(reset_data)
    );
    
    storage_element storage (
        .clk(clk),
        .data_in(reset_data),
        .data_out(ff_out)
    );
    
    output_stage output_ctrl (
        .data_in(ff_out),
        .data_out(q)
    );
endmodule

// 输入处理子模块：处理复位条件和数据输入
module input_stage #(
    parameter RESET_VALUE = 1'b0
)(
    input  wire rst,
    input  wire d,
    input  wire reset_value,
    output wire out
);
    // 复位逻辑 - 当rst为高时输出复位值，否则传递输入数据
    assign out = rst ? reset_value : d;
endmodule

// 存储单元子模块：处理时序逻辑
module storage_element (
    input  wire clk,
    input  wire data_in,
    output reg  data_out
);
    // 时序逻辑实现
    always @(posedge clk) begin
        data_out <= data_in;
    end
endmodule

// 输出处理子模块：处理输出逻辑
module output_stage (
    input  wire data_in,
    output wire data_out
);
    // 输出缓冲，可用于添加额外逻辑（如启用控制）
    assign data_out = data_in;
endmodule