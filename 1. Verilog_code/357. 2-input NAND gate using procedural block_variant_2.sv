//SystemVerilog
module nand2_3 (
    input  wire clk,    // 添加时钟输入以支持流水线
    input  wire rst_n,  // 添加复位信号
    input  wire A,
    input  wire B,
    output wire Y
);
    // 内部信号定义 - 用于流水线阶段
    reg  stage1_A_inv;
    reg  stage1_B_inv;
    reg  stage2_result;

    // 第一级流水线：计算输入的反向值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A_inv <= 1'b0;
            stage1_B_inv <= 1'b0;
        end else begin
            stage1_A_inv <= ~A;  // A的反向值
            stage1_B_inv <= ~B;  // B的反向值
        end
    end

    // 第二级流水线：进行或运算生成最终结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_A_inv | stage1_B_inv;  // 根据德摩根定律
        end
    end

    // 输出赋值
    assign Y = stage2_result;

endmodule