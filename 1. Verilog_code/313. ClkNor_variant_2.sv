//SystemVerilog
module ClkNor(
    input clk,
    input a,
    input b,
    output reg y
);
    reg a_reg, b_reg;
    
    // 将寄存器前移到输入端
    always @(posedge clk) begin
        a_reg <= a;
        b_reg <= b;
    end
    
    // 使用德摩根定律: ~(a | b) = (~a & ~b)
    // 输出逻辑现在使用已寄存的输入
    always @(posedge clk)
        y <= (~a_reg & ~b_reg);
endmodule