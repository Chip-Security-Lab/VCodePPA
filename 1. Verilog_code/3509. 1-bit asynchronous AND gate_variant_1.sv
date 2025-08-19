//SystemVerilog
// 重组的1-bit与门模块，具有更清晰的数据流结构
module and_gate_1_async (
    input  wire data_in_a,    // 输入数据A
    input  wire data_in_b,    // 输入数据B
    output wire data_out_y    // 输出结果Y
);
    // 内部信号定义，用于提高数据流清晰度
    wire input_stage_a;
    wire input_stage_b;
    wire logic_output;
    
    // 输入数据缓冲阶段
    assign input_stage_a = data_in_a;
    assign input_stage_b = data_in_b;
    
    // 核心逻辑计算阶段
    assign logic_output = input_stage_a & input_stage_b;
    
    // 输出驱动阶段
    assign data_out_y = logic_output;
    
endmodule