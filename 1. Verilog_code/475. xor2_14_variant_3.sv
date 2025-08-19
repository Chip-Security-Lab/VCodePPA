//SystemVerilog
module xor2_14 (
    input  wire clk,    // 添加时钟信号以实现适当的流水线
    input  wire rst_n,  // 添加复位信号以确保可靠初始化
    input  wire A,      // 输入信号A
    input  wire B,      // 输入信号B
    output reg  Y       // 输出结果Y
);
    // 内部信号定义 - 创建清晰的数据流路径
    reg stage1_a, stage1_b;    // 第一级流水线寄存器
    reg stage2_result;         // 第二级流水线寄存器

    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= A;
            stage1_b <= B;
        end
    end

    // 第二级流水线 - 计算XOR并寄存结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
        end else begin
            stage2_result <= stage1_a ^ stage1_b;
        end
    end

    // 输出寄存器 - 最终结果输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_result;
        end
    end
endmodule