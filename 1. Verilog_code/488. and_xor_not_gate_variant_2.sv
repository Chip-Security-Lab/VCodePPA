//SystemVerilog
//IEEE 1364-2005
module and_xor_not_gate (
    input  wire clk,      // 时钟信号
    input  wire rst_n,    // 复位信号（低有效）
    input  wire A, B, C,  // 输入A, B, C
    output wire Y         // 输出Y
);
    // 第一级流水线 - 计算与操作
    reg and_result_r;
    wire and_result = A & B;
    
    // 第二级流水线 - 计算异或操作
    reg xor_result_r;
    wire xor_result = and_result_r ^ C;
    
    // 第三级流水线 - 计算非操作
    reg not_A_r;
    wire not_A = ~A;
    
    // 第四级流水线 - 最终结果计算
    reg Y_r;
    assign Y = Y_r;
    
    // 流水线寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            and_result_r <= 1'b0;
            xor_result_r <= 1'b0;
            not_A_r <= 1'b0;
            Y_r <= 1'b0;
        end else begin
            and_result_r <= and_result;
            xor_result_r <= xor_result;
            not_A_r <= not_A;
            Y_r <= xor_result_r & not_A_r;
        end
    end
    
endmodule