//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块
module xor_function #(
    parameter PIPELINE_STAGES = 2
)(
    input wire clk,        // 时钟信号
    input wire rst_n,      // 复位信号
    input wire a_in,       // 输入操作数A
    input wire b_in,       // 输入操作数B
    input wire data_valid, // 输入数据有效信号
    output wire y_out,     // 输出结果
    output wire result_valid // 输出结果有效信号
);
    // 内部信号声明
    wire [PIPELINE_STAGES:0] stage_data_valid;
    wire [PIPELINE_STAGES:0] stage_result;
    
    // 输入阶段
    assign stage_data_valid[0] = data_valid;
    assign stage_result[0] = a_in ^ b_in; // 直接使用XOR运算符提高效率
    
    // 生成流水线阶段
    genvar i;
    generate
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin : xor_pipeline
            data_pipeline_stage stage (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(stage_result[i]),
                .valid_in(stage_data_valid[i]),
                .data_out(stage_result[i+1]),
                .valid_out(stage_data_valid[i+1])
            );
        end
    endgenerate
    
    // 输出赋值
    assign y_out = stage_result[PIPELINE_STAGES];
    assign result_valid = stage_data_valid[PIPELINE_STAGES];
endmodule

// 流水线阶段模块
module data_pipeline_stage (
    input wire clk,
    input wire rst_n,
    input wire data_in,
    input wire valid_in,
    output reg data_out,
    output reg valid_out
);
    // 流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            data_out <= data_in;
            valid_out <= valid_in;
        end
    end
endmodule