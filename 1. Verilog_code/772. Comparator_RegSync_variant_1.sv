//SystemVerilog
module Comparator_RegSync #(parameter WIDTH = 8) (
    input               clk,      // 全局时钟
    input               rst_n,    // 低有效同步复位
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output reg          eq_out    // 寄存后的比较结果
);
    // 使用条件反相比较逻辑
    wire [WIDTH-1:0] xor_result;  // 异或结果
    wire eq_comb;                 // 组合逻辑比较结果
    
    // 异或运算检测不同位
    assign xor_result = in1 ^ in2;
    // 如果所有位都相同(异或结果全为0)，则相等
    assign eq_comb = ~|xor_result;
    
    // 寄存器更新逻辑
    always @(posedge clk) begin
        if (!rst_n)
            eq_out <= 1'b0;
        else
            eq_out <= eq_comb;
    end
endmodule