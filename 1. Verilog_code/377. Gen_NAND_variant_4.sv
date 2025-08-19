//SystemVerilog
//IEEE 1364-2005 Verilog Standard
module Gen_NAND (
    input wire [15:0] vec_a, vec_b,
    input wire clk,
    input wire rst_n,
    output reg [15:0] result
);
    // 内部流水线寄存器
    reg [15:0] vec_a_inv_stage1;
    reg [15:0] vec_b_inv_stage1;
    reg [15:0] result_stage2;
    
    // 合并所有具有相同时钟和复位触发条件的always块
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 复位所有寄存器
            vec_a_inv_stage1 <= 16'h0000;
            vec_b_inv_stage1 <= 16'h0000;
            result_stage2 <= 16'h0000;
            result <= 16'h0000;
        end else begin
            // 第一级流水线: 输入求反
            vec_a_inv_stage1 <= ~vec_a;  // 向量A取反
            vec_b_inv_stage1 <= ~vec_b;  // 向量B取反
            
            // 第二级流水线: 或运算
            result_stage2 <= vec_a_inv_stage1 | vec_b_inv_stage1;  // 应用德摩根定律
            
            // 输出赋值
            result <= result_stage2;
        end
    end
endmodule