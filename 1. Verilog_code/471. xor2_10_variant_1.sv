//SystemVerilog
module xor2_10 (
    input wire clk,
    input wire rst_n,
    input wire A, B,
    output reg Y
);
    // 内部信号声明 - 优化的流水线结构
    reg stage1_a, stage1_b;
    reg stage2_xor;  // 直接计算XOR结果，减少逻辑深度

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

    // 第二级流水线 - 直接计算XOR结果
    // 使用A^B替代(A&B)|(~A&~B)，减少逻辑层级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xor <= 1'b0;
        end else begin
            stage2_xor <= stage1_a ^ stage1_b;
        end
    end

    // 第三级流水线 - 传递结果到输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y <= 1'b0;
        end else begin
            Y <= stage2_xor;
        end
    end

endmodule