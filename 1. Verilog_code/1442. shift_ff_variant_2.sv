//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块
module shift_ff (
    input  wire clk,   // 时钟信号
    input  wire rstn,  // 复位信号
    input  wire sin,   // 串行输入
    output wire q      // 输出
);

    // 内部连线
    wire preprocessed_input;
    wire processed_output;
    
    // 实例化输入处理子模块
    input_processor input_proc (
        .clk(clk),
        .rstn(rstn),
        .raw_input(sin),
        .processed_input(preprocessed_input)
    );
    
    // 实例化核心处理子模块
    core_processor core_proc (
        .clk(clk),
        .rstn(rstn),
        .data_in(preprocessed_input),
        .data_out(processed_output)
    );
    
    // 实例化输出处理子模块
    output_processor output_proc (
        .clk(clk),
        .rstn(rstn),
        .data_in(processed_output),
        .final_output(q)
    );

endmodule

// 输入处理子模块
module input_processor (
    input  wire clk,
    input  wire rstn,
    input  wire raw_input,
    output wire processed_input
);
    // 简单的输入处理，直接传递
    assign processed_input = raw_input;
endmodule

// 核心处理子模块
module core_processor (
    input  wire clk,
    input  wire rstn,
    input  wire data_in,
    output wire data_out
);
    // 核心处理逻辑，直接传递
    assign data_out = data_in;
endmodule

// 输出处理子模块
module output_processor (
    input  wire clk,
    input  wire rstn,
    input  wire data_in,
    output wire final_output
);
    // 输出处理逻辑，直接传递
    assign final_output = data_in;
endmodule