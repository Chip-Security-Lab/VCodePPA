//SystemVerilog
//IEEE 1364-2005 Verilog
// 顶层模块 - 优化的NAND2实现
module nand2_12 (
    input  wire clk,    // 新增时钟输入用于流水线控制
    input  wire rst_n,  // 新增复位信号
    input  wire A, B,   // 输入信号
    output wire Y       // 输出信号
);
    // 内部流水线寄存器
    reg  stage1_a_reg, stage1_b_reg;  // 第一级流水线寄存器
    wire stage1_and_out;              // 第一级组合逻辑输出
    reg  stage2_and_out_reg;          // 第二级流水线寄存器
    
    // 第一级流水线 - 输入寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a_reg <= 1'b0;
            stage1_b_reg <= 1'b0;
        end else begin
            stage1_a_reg <= A;
            stage1_b_reg <= B;
        end
    end
    
    // 第一级组合逻辑 - AND操作
    assign stage1_and_out = stage1_a_reg & stage1_b_reg;
    
    // 第二级流水线 - 中间寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_and_out_reg <= 1'b0;
        end else begin
            stage2_and_out_reg <= stage1_and_out;
        end
    end
    
    // 最终组合逻辑 - NOT操作
    assign Y = ~stage2_and_out_reg;
    
endmodule