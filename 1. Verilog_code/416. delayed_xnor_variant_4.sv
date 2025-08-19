//SystemVerilog
// SystemVerilog
module delayed_xnor (
    input wire clk,        // 时钟输入
    input wire rst_n,      // 复位信号
    input wire a,          // 输入 a
    input wire b,          // 输入 b
    output wire y          // 输出 y
);

    // 内部信号定义
    reg stage1_a, stage1_b;   // 第一级流水线寄存器
    reg stage2_xnor_result;   // 第二级流水线寄存器 - 存储XNOR结果
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_a <= 1'b0;
            stage1_b <= 1'b0;
        end else begin
            stage1_a <= a;
            stage1_b <= b;
        end
    end
    
    // 第二级流水线 - XNOR操作(使用等价布尔表达式优化)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_xnor_result <= 1'b0;
        end else begin
            // 优化: ~(a^b) 等价于 (a&b)|(~a&~b)
            stage2_xnor_result <= (stage1_a & stage1_b) | (~stage1_a & ~stage1_b);
        end
    end
    
    // 输出赋值
    assign y = stage2_xnor_result;
    
endmodule