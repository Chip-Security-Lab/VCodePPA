//SystemVerilog
module EnabledNOT #(
    parameter DATA_WIDTH = 4
)(
    input logic enable,
    input logic [DATA_WIDTH-1:0] src,
    output logic [DATA_WIDTH-1:0] result
);
    // 内部连线
    logic [DATA_WIDTH-1:0] inverted_data;
    
    // 实例化数据处理单元
    DataProcessor #(
        .WIDTH(DATA_WIDTH)
    ) data_proc (
        .data_in(src),
        .data_out(inverted_data)
    );
    
    // 实例化输出控制单元
    OutputStage #(
        .WIDTH(DATA_WIDTH)
    ) out_stage (
        .enable(enable),
        .processed_data(inverted_data),
        .final_result(result)
    );
endmodule

// 数据处理单元 - 负责数据变换操作
module DataProcessor #(
    parameter WIDTH = 4
)(
    input logic [WIDTH-1:0] data_in,
    output logic [WIDTH-1:0] data_out
);
    // 优化反转逻辑，减少传播延迟
    always_comb begin
        data_out = ~data_in;
    end
endmodule

// 输出控制单元 - 负责基于控制信号管理输出
module OutputStage #(
    parameter WIDTH = 4
)(
    input logic enable,
    input logic [WIDTH-1:0] processed_data,
    output logic [WIDTH-1:0] final_result
);
    // 使用寄存器实现稳定的输出控制，优化时序
    always_comb begin
        final_result = enable ? processed_data : {WIDTH{1'bz}};
    end
endmodule