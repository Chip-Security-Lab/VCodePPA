//SystemVerilog
module struct_input_xnor (
    input wire clk,        // 添加时钟信号用于流水线寄存器
    input wire rst_n,      // 添加复位信号
    input wire [3:0] a_in,
    input wire [3:0] b_in,
    output reg [3:0] struct_out
);
    // 定义流水线寄存器
    reg [3:0] a_stage1, b_stage1;
    reg [3:0] a_and_b_stage2, not_a_and_not_b_stage2;
    
    // 第一级流水线 - 输入寄存和预处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 4'b0000;
            b_stage1 <= 4'b0000;
        end else begin
            a_stage1 <= a_in;
            b_stage1 <= b_in;
        end
    end
    
    // 第二级流水线 - 并行计算中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_and_b_stage2 <= 4'b0000;
            not_a_and_not_b_stage2 <= 4'b0000;
        end else begin
            a_and_b_stage2 <= a_stage1 & b_stage1;
            not_a_and_not_b_stage2 <= (~a_stage1) & (~b_stage1);
        end
    end
    
    // 第三级流水线 - 合并结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            struct_out <= 4'b0000;
        end else begin
            struct_out <= a_and_b_stage2 | not_a_and_not_b_stage2;
        end
    end
    
endmodule