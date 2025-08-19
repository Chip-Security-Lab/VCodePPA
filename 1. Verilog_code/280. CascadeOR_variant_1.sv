//SystemVerilog
module CascadeOR(
    input wire clk,
    input wire rst_n,
    input wire [2:0] in,
    output reg out
);
    // 流水线寄存器
    reg [2:0] in_reg;
    reg stage1_result;
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk or negedge rst_n)
        in_reg <= (!rst_n) ? 3'b000 : in;
    
    // 第二级流水线 - 第一阶段计算
    always @(posedge clk or negedge rst_n)
        stage1_result <= (!rst_n) ? 1'b0 : (in_reg[0] | in_reg[1]);
    
    // 第三级流水线 - 最终结果计算
    always @(posedge clk or negedge rst_n)
        out <= (!rst_n) ? 1'b0 : (stage1_result | in_reg[2]);
    
endmodule