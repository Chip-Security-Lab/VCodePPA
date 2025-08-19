//SystemVerilog
module xor2_16 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    // 时序逻辑部分 - 寄存器存储
    reg A_reg, B_reg;
    
    // 组合逻辑部分 - 计算XOR结果
    wire xor_result;
    
    // 时序逻辑模块 - 仅在时钟边沿处理寄存器更新
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
    
    // 组合逻辑模块 - 处理XOR操作
    assign xor_result = A_reg ^ B_reg;
    
    // 输出赋值
    assign Y = xor_result;
endmodule