//SystemVerilog
module xor2_19 (
    input  wire clk,    // 时钟输入用于流水线寄存器
    input  wire rst_n,  // 复位信号
    input  wire A,      // 输入A
    input  wire B,      // 输入B
    output wire Y       // 输出Y
);
    // 直接计算XOR结果
    wire xor_result;
    assign xor_result = A ^ B;
    
    // 单级流水线 - 将寄存器移到组合逻辑之后
    reg result_reg;
    
    // 捕获XOR计算结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 1'b0;
        end else begin
            result_reg <= xor_result;
        end
    end
    
    // 输出赋值
    assign Y = result_reg;
    
endmodule