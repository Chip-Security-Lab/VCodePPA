//SystemVerilog
module d_ff_async_reset (
    input  wire clk,    // 系统时钟
    input  wire rst_n,  // 异步低电平复位信号
    input  wire d,      // 数据输入
    output wire q       // 数据输出
);
    // 内部信号声明
    reg q_reg;          // 数据存储寄存器
    
    // 直接将输入数据注册到输出寄存器
    // 移除了中间的d_sampled寄存器，减少了关键路径长度
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_reg <= 1'b0;
        end else begin
            q_reg <= d;
        end
    end
    
    // 连续赋值输出
    assign q = q_reg;
    
endmodule