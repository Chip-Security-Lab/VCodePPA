//SystemVerilog
// 顶层模块
module HybridNOT(
    input [7:0] byte_in,
    output [7:0] byte_out
);
    // 数据分割与组合控制
    wire [3:0] lower_nibble_in, upper_nibble_in;
    wire [3:0] lower_nibble_out, upper_nibble_out;
    
    // 数据分割单元
    DataSplitter data_splitter_inst (
        .byte_in(byte_in),
        .lower_nibble(lower_nibble_in),
        .upper_nibble(upper_nibble_in)
    );
    
    // 位反转处理单元
    NibbleProcessingUnit nibble_processing_unit (
        .lower_nibble_in(lower_nibble_in),
        .upper_nibble_in(upper_nibble_in),
        .lower_nibble_out(lower_nibble_out),
        .upper_nibble_out(upper_nibble_out)
    );
    
    // 数据合并单元
    DataMerger data_merger_inst (
        .upper_nibble(upper_nibble_out),
        .lower_nibble(lower_nibble_out),
        .byte_out(byte_out)
    );
    
endmodule

// 数据分割子模块
module DataSplitter(
    input [7:0] byte_in,
    output [3:0] lower_nibble,
    output [3:0] upper_nibble
);
    // 优化分割逻辑，减少资源消耗
    assign lower_nibble = byte_in[3:0];
    assign upper_nibble = byte_in[7:4];
endmodule

// 数据合并子模块
module DataMerger(
    input [3:0] upper_nibble,
    input [3:0] lower_nibble,
    output [7:0] byte_out
);
    // 优化合并逻辑，减少资源和延迟
    assign byte_out = {upper_nibble, lower_nibble};
endmodule

// Nibble处理单元 - 管理两个Nibble的并行处理
module NibbleProcessingUnit(
    input [3:0] lower_nibble_in,
    input [3:0] upper_nibble_in,
    output [3:0] lower_nibble_out,
    output [3:0] upper_nibble_out
);
    // 常量参数化，增加设计灵活性
    localparam NIBBLE_MASK = 4'hF;
    
    // 双通道并行处理架构，提高吞吐量
    BitManipulationEngine #(.WIDTH(4)) lower_inverter (
        .data_in(lower_nibble_in),
        .operation_mode(2'b01), // 反转模式
        .mask(NIBBLE_MASK),
        .data_out(lower_nibble_out)
    );
    
    BitManipulationEngine #(.WIDTH(4)) upper_inverter (
        .data_in(upper_nibble_in),
        .operation_mode(2'b01), // 反转模式
        .mask(NIBBLE_MASK),
        .data_out(upper_nibble_out)
    );
endmodule

// 增强型位操作引擎 - 使用查找表实现多种位操作
module BitManipulationEngine #(
    parameter WIDTH = 4
)(
    input [WIDTH-1:0] data_in,
    input [1:0] operation_mode, // 00: 直通, 01: XOR反转, 10: 与操作, 11: 或操作
    input [WIDTH-1:0] mask,
    output [WIDTH-1:0] data_out
);
    // 使用查找表预计算所有可能的操作结果
    reg [WIDTH-1:0] operation_lut [0:3];
    
    // 预计算所有操作结果
    always @(*) begin
        operation_lut[0] = data_in;        // 直通模式
        operation_lut[1] = data_in ^ mask; // XOR反转
        operation_lut[2] = data_in & mask; // 与操作
        operation_lut[3] = data_in | mask; // 或操作
    end
    
    // 使用索引直接查找结果，避免条件分支
    assign data_out = operation_lut[operation_mode];
    
endmodule