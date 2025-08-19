//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块 - 重构的数据流路径
module and_xor_not_gate (
    input  wire clk,         // 添加时钟信号用于流水线
    input  wire rst_n,       // 添加复位信号
    input  wire A, B, C,     // 输入A, B, C
    output wire Y            // 输出Y
);
    // 数据通路寄存器声明
    reg stage1_A, stage1_B;  // 第一级流水线寄存器
    reg stage1_and_result;   // 第一级与运算结果
    reg stage2_and_result;   // 第二级流水线寄存器
    reg stage2_C;            // 第二级输入C寄存器
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_A <= 1'b0;
            stage1_B <= 1'b0;
        end else begin
            stage1_A <= A;
            stage1_B <= B;
        end
    end
    
    // 第一级流水线 - 与运算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_and_result <= 1'b0;
        end else begin
            stage1_and_result <= stage1_A & stage1_B;
        end
    end
    
    // 第二级流水线 - 传递和寄存C输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_result <= 1'b0;
            stage2_C <= 1'b0;
        end else begin
            stage2_and_result <= stage1_and_result;
            stage2_C <= C;
        end
    end
    
    // 最终输出 - 同或操作
    assign Y = stage2_and_result ~^ stage2_C;
    
endmodule