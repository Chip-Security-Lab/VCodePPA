//SystemVerilog
`timescale 1ns / 1ps
module int_ctrl_dyn_prio #(parameter N = 4)(
    input wire clk,               // 系统时钟
    input wire [N-1:0] int_req,   // 中断请求信号
    input wire [N-1:0] prio_reg,  // 优先级寄存器
    output reg [N-1:0] grant      // 中断授权输出
);
    // 使用wire而不是寄存器进行中间计算，提高并行性
    wire [N-1:0] masked_reqs;
    
    // 优化的中断请求掩码计算
    assign masked_reqs = int_req & prio_reg;
    
    // 使用阻塞赋值提高综合效率
    always @(*) begin
        integer i;
        grant = {N{1'b0}}; // 初始化为全0，使用参数化位宽重复
        
        // 实现优先级编码逻辑
        if (|masked_reqs) begin // 检查是否有任何有效请求，减少不必要的迭代
            i = 0; // 初始化循环变量
            while (i < N) begin
                if (masked_reqs[i]) begin
                    grant[i] = 1'b1;
                end
                i = i + 1; // 迭代步骤放在循环体末尾
            end
        end
    end
endmodule