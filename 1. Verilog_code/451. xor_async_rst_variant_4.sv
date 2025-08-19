//SystemVerilog
module xor_async_rst(
    input wire clk,      // 系统时钟
    input wire rst_n,    // 异步低电平复位
    input wire a,        // 输入数据A
    input wire b,        // 输入数据B
    output reg y         // 异或结果输出
);

    // 内部信号声明 - 定义清晰的数据流
    reg logic_result;    // 组合逻辑结果寄存器
    
    // 第一阶段：组合逻辑计算
    always @(*) begin
        logic_result = a ^ b;  // 计算异或结果
    end
    
    // 第二阶段：时序逻辑和复位控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y <= 1'b0;         // 异步复位
        end else begin
            y <= logic_result; // 将计算结果传递到输出
        end
    end

endmodule