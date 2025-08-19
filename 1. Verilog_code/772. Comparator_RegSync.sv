// 带时钟和同步复位的寄存器输出比较器
module Comparator_RegSync #(parameter WIDTH = 4) (
    input               clk,      // 全局时钟
    input               rst_n,    // 低有效同步复位
    input  [WIDTH-1:0]  in1,      // 输入向量1
    input  [WIDTH-1:0]  in2,      // 输入向量2
    output reg          eq_out    // 寄存后的比较结果
);
    always @(posedge clk) begin
        if (!rst_n) eq_out <= 1'b0;
        else        eq_out <= (in1 == in2);
    end
endmodule