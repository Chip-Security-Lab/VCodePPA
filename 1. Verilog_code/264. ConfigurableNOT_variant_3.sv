//SystemVerilog
// 顶层模块
module ConfigurableNOT #(
    parameter DATA_WIDTH = 8
)(
    input                   pol,    // 极性控制
    input  [DATA_WIDTH-1:0] in,     // 输入数据
    output [DATA_WIDTH-1:0] out     // 输出数据
);
    // 内部连线
    wire [DATA_WIDTH-1:0] inverted_data;

    // 实例化数据处理模块
    DataProcessor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) data_processor_inst (
        .data_in(in),
        .pol(pol),
        .data_out(out)
    );
endmodule

// 数据处理模块 - 整合反相和选择功能
module DataProcessor #(
    parameter DATA_WIDTH = 8
)(
    input  [DATA_WIDTH-1:0] data_in,  // 输入数据
    input                   pol,      // 极性控制
    output [DATA_WIDTH-1:0] data_out  // 输出数据
);
    // 内部信号
    wire [DATA_WIDTH-1:0] inverted_data;
    
    // 反相路径 - 内联实现提高性能
    assign inverted_data = ~data_in;
    
    // 路径选择 - 使用三元运算符简化逻辑
    assign data_out = pol ? inverted_data : data_in;
endmodule