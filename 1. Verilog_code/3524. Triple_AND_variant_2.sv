//SystemVerilog
module Triple_AND (
    input  wire clk,      // 时钟信号
    input  wire rst_n,    // 低电平有效复位
    input  wire a, b, c,  // 输入信号
    output reg  out       // 输出信号
);
    // 数据流水线寄存器
    reg stage1_a, stage1_b;    // 第一级流水线寄存器
    reg stage1_ab_and;         // 第一级AND结果
    reg stage2_c;              // 第二级C信号寄存器
    
    // 第一级流水线 - 寄存A和B信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end
    
    // 第一级流水线计算 - A与B的AND结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_ab_and <= 1'b0;
        end else begin
            stage1_ab_and <= stage1_a & stage1_b;
        end
    end
    
    // 第二级流水线 - 寄存C信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_c <= 1'b0;
        end else begin
            stage2_c <= c;
        end
    end
    
    // 最终输出计算 - 第一级AND结果与C的AND
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 1'b0;
        end else begin
            out <= stage1_ab_and & stage2_c;
        end
    end
    
endmodule