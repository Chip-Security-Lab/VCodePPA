//SystemVerilog
module param_jk_register #(
    parameter WIDTH = 4
) (
    input wire clk,
    input wire [WIDTH-1:0] j,
    input wire [WIDTH-1:0] k,
    output reg [WIDTH-1:0] q
);
    // 寄存器预先存储输入信号
    reg [WIDTH-1:0] j_reg, k_reg;
    
    // 输入寄存器化 - 将寄存器前移
    always @(posedge clk) begin
        j_reg <= j;
        k_reg <= k;
    end
    
    // 重定时后的逻辑 - 使用寄存器化的输入
    always @(posedge clk) begin
        q <= (q & ~k_reg) | (j_reg & ~q) | (j_reg & k_reg & ~q) | (~j_reg & ~k_reg & q);
    end
endmodule