//SystemVerilog
// 顶层模块
module Demux_Bidirectional #(
    parameter N  = 4,
    parameter DW = 8
) (
    inout  [DW-1:0]        io_port,
    input                  dir,      // 0:in, 1:out
    input  [N-1:0]         sel,
    output [DW-1:0]        data_in,
    input  [N-1:0][DW-1:0] data_out
);
    // 内部信号定义
    wire [DW-1:0] selected_data;
    
    // 输入通道实现
    assign data_in = io_port;
    
    // 使用条件求和减法算法实现数据选择
    // 这里使用一种基于条件求和的方法替代原始的多路选择器实现
    generate
        genvar i;
        for (i = 0; i < DW; i = i + 1) begin: bit_select
            wire [N-1:0] bit_values;
            wire [N-1:0] carry;
            
            // 提取每个数据源的对应位
            for (genvar j = 0; j < N; j = j + 1) begin: extract_bits
                assign bit_values[j] = data_out[j][i];
            end
            
            // 条件求和减法实现的数据选择
            assign carry[0] = 1'b0;
            for (genvar k = 1; k < N; k = k + 1) begin: carry_gen
                assign carry[k] = carry[k-1] ^ (sel[k-1] & bit_values[k-1]);
            end
            
            assign selected_data[i] = ^(bit_values & sel) ^ carry[N-1];
        end
    endgenerate
    
    // 输出控制
    assign io_port = dir ? selected_data : {DW{1'bz}};
    
endmodule