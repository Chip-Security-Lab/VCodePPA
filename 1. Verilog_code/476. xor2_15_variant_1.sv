//SystemVerilog
module xor2_15 (
    input  wire clk,    // 添加时钟输入以支持流水线结构
    input  wire rst_n,  // 添加复位信号
    input  wire A,
    input  wire B,
    output wire Y
);
    // 第一级流水线 - 生成中间信号
    reg notA_r, notB_r, A_r, B_r;
    
    // 第二级流水线 - 计算部分结果
    reg path1_r, path2_r;
    
    // 最终输出寄存器
    reg Y_r;
    
    // 第一级流水线 - 输入缓存并生成非操作
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            notA_r <= 1'b0;
            notB_r <= 1'b0;
            A_r <= 1'b0;
            B_r <= 1'b0;
        end else begin
            notA_r <= ~A;
            notB_r <= ~B;
            A_r <= A;
            B_r <= B;
        end
    end
    
    // 第二级流水线 - 计算异或操作的两条路径
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            path1_r <= 1'b0;
            path2_r <= 1'b0;
        end else begin
            path1_r <= A_r & notB_r;  // A AND (NOT B)
            path2_r <= notA_r & B_r;  // (NOT A) AND B
        end
    end
    
    // 第三级流水线 - 合并两条路径的结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            Y_r <= 1'b0;
        end else begin
            Y_r <= path1_r | path2_r;  // 最终OR操作
        end
    end
    
    // 输出赋值
    assign Y = Y_r;
    
endmodule