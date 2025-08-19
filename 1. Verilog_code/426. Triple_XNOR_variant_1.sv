//SystemVerilog
// 顶层模块 - 四输入XNOR逻辑处理器
module Triple_XNOR #(
    parameter PIPELINE_STAGES = 2  // 可配置的流水线级数
)(
    input  wire clk,               // 时钟输入
    input  wire rst_n,             // 复位信号，低电平有效
    input  wire a, b, c, d,        // 输入信号
    output wire y                  // 输出信号
);
    // 内部流水线寄存器
    reg [PIPELINE_STAGES-1:0] stage_valid;  // 流水线有效信号
    
    // 数据路径信号
    wire data_path_1_result;
    wire data_path_2_result;
    wire xnor_pre_output;
    wire xnor_final_output;
    
    // 第一级流水线 - 输入数据路径1
    Input_DataPath_1 u_data_path_1 (
        .clk(clk),
        .rst_n(rst_n),
        .in_a(a),
        .in_b(b),
        .out_result(data_path_1_result)
    );
    
    // 第一级流水线 - 输入数据路径2
    Input_DataPath_2 u_data_path_2 (
        .clk(clk),
        .rst_n(rst_n),
        .in_c(c),
        .in_d(d),
        .out_result(data_path_2_result)
    );
    
    // 第二级流水线 - 组合数据路径
    XNOR_Combiner u_xnor_combiner (
        .clk(clk),
        .rst_n(rst_n),
        .in_path1(data_path_1_result),
        .in_path2(data_path_2_result),
        .out_xnor(xnor_pre_output)
    );
    
    // 输出阶段 - 缓冲和反转
    Output_Stage u_output_stage (
        .clk(clk),
        .rst_n(rst_n),
        .in(xnor_pre_output),
        .out(y)
    );
    
    // 流水线有效信号控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_valid <= {PIPELINE_STAGES{1'b0}};
        end else begin
            stage_valid <= {stage_valid[PIPELINE_STAGES-2:0], 1'b1};
        end
    end
    
endmodule

// 输入数据路径1处理模块 - 处理a和b输入
module Input_DataPath_1 (
    input  wire clk,
    input  wire rst_n,
    input  wire in_a,
    input  wire in_b,
    output reg  out_result
);
    // 内部信号
    wire path1_xor_result;
    
    // 组合逻辑 - XOR操作
    assign path1_xor_result = in_a ^ in_b;
    
    // 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_result <= 1'b0;
        end else begin
            out_result <= path1_xor_result;
        end
    end
endmodule

// 输入数据路径2处理模块 - 处理c和d输入
module Input_DataPath_2 (
    input  wire clk,
    input  wire rst_n,
    input  wire in_c,
    input  wire in_d,
    output reg  out_result
);
    // 内部信号
    wire path2_xor_result;
    
    // 组合逻辑 - XOR操作
    assign path2_xor_result = in_c ^ in_d;
    
    // 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_result <= 1'b0;
        end else begin
            out_result <= path2_xor_result;
        end
    end
endmodule

// XNOR组合器模块 - 合并两条数据路径的结果
module XNOR_Combiner (
    input  wire clk,
    input  wire rst_n,
    input  wire in_path1,
    input  wire in_path2,
    output reg  out_xnor
);
    // 内部信号
    wire combined_xor_result;
    
    // 组合逻辑 - 合并两路输入并进行XOR操作
    assign combined_xor_result = in_path1 ^ in_path2;
    
    // 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_xnor <= 1'b0;
        end else begin
            out_xnor <= combined_xor_result;
        end
    end
endmodule

// 输出阶段模块 - 缓冲并反转输出信号
module Output_Stage (
    input  wire clk,
    input  wire rst_n,
    input  wire in,
    output reg  out
);
    // 内部信号
    wire inverted_signal;
    
    // 组合逻辑 - 取反以实现XNOR
    assign inverted_signal = ~in;
    
    // 输出寄存器缓冲
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            out <= inverted_signal;
        end
    end
endmodule