//SystemVerilog
//-----------------------------------------------------------------------------
// 顶层模块: 锯齿波发生器
//-----------------------------------------------------------------------------
module wave6_sawtooth #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output wire [WIDTH-1:0] wave_out
);
    // 内部连线
    wire [WIDTH-1:0] count_value;
    
    // 计数器子模块实例化
    sawtooth_counter #(
        .COUNTER_WIDTH(WIDTH)
    ) counter_inst (
        .clk         (clk),
        .rst         (rst),
        .count_value (count_value)
    );
    
    // 输出驱动子模块实例化
    wave_output_driver #(
        .DATA_WIDTH(WIDTH)
    ) output_driver_inst (
        .data_in  (count_value),
        .data_out (wave_out)
    );
    
endmodule

//-----------------------------------------------------------------------------
// 子模块: 锯齿波计数器 - 负责生成递增计数
//-----------------------------------------------------------------------------
module sawtooth_counter #(
    parameter COUNTER_WIDTH = 8
)(
    input  wire                     clk,
    input  wire                     rst,
    output reg  [COUNTER_WIDTH-1:0] count_value
);
    // 计数器逻辑 - 使用条件运算符替代if-else结构
    always @(posedge clk or posedge rst) begin
        count_value <= rst ? {COUNTER_WIDTH{1'b0}} : count_value + 1'b1;
    end
endmodule

//-----------------------------------------------------------------------------
// 子模块: 波形输出驱动器 - 负责驱动输出信号
//-----------------------------------------------------------------------------
module wave_output_driver #(
    parameter DATA_WIDTH = 8
)(
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 当前简单直通，但保留此模块以便未来增强
    // 例如添加缩放、偏移或波形修改功能
    assign data_out = data_in;
endmodule