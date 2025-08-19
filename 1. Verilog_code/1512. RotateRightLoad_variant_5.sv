//SystemVerilog
// IEEE 1364-2005 Verilog标准
module RotateRightLoad #(parameter DATA_WIDTH=8) (
    input wire clk,
    input wire rst_n,        // 复位信号
    input wire load_en,
    input wire data_valid_in, // 输入数据有效信号
    input wire [DATA_WIDTH-1:0] parallel_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg data_valid_out  // 输出数据有效信号
);

    // 优化的流水线寄存器
    reg data_valid_pipe1, data_valid_pipe2;
    reg load_en_pipe1;
    reg [DATA_WIDTH-1:0] parallel_in_pipe1;
    reg [DATA_WIDTH-1:0] rotated_data;
    
    // 计算旋转结果，使用组合逻辑进行优化
    wire [DATA_WIDTH-1:0] rotate_result = {data_out[0], data_out[DATA_WIDTH-1:1]};
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_valid_pipe1 <= 1'b0;
            load_en_pipe1 <= 1'b0;
            parallel_in_pipe1 <= {DATA_WIDTH{1'b0}};
        end else begin
            data_valid_pipe1 <= data_valid_in;
            load_en_pipe1 <= load_en;
            parallel_in_pipe1 <= parallel_in;
        end
    end
    
    // 第二级流水线寄存器 - 执行旋转或载入操作
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rotated_data <= {DATA_WIDTH{1'b0}};
            data_valid_pipe2 <= 1'b0;
        end else begin
            data_valid_pipe2 <= data_valid_pipe1;
            // 使用三元运算符提高效率
            rotated_data <= load_en_pipe1 ? parallel_in_pipe1 : rotate_result;
        end
    end
    
    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_out <= {DATA_WIDTH{1'b0}};
            data_valid_out <= 1'b0;
        end else begin
            data_out <= rotated_data;
            data_valid_out <= data_valid_pipe2;
        end
    end

endmodule