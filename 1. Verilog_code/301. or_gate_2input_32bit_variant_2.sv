//SystemVerilog
module or_gate_2input_32bit (
    input wire clk,          // 时钟信号
    input wire rst_n,        // 复位信号
    input wire [31:0] a,     // 输入数据a
    input wire [31:0] b,     // 输入数据b
    input wire data_valid,   // 输入数据有效
    output reg [31:0] y,     // 输出结果
    output reg result_valid  // 输出结果有效
);

    // 内部流水线寄存器
    reg [31:0] a_reg, b_reg;
    reg [31:0] or_result;
    reg data_valid_stage1, data_valid_stage2;
    
    // 第一级流水线：输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 32'b0;
            b_reg <= 32'b0;
            data_valid_stage1 <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            data_valid_stage1 <= data_valid;
        end
    end
    
    // 第二级流水线：执行OR操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result <= 32'b0;
            data_valid_stage2 <= 1'b0;
        end else begin
            or_result <= a_reg | b_reg;
            data_valid_stage2 <= data_valid_stage1;
        end
    end
    
    // 第三级流水线：输出寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 32'b0;
            result_valid <= 1'b0;
        end else begin
            y <= or_result;
            result_valid <= data_valid_stage2;
        end
    end
    
endmodule