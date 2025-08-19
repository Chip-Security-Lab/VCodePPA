//SystemVerilog
module xor2_16 (
    input wire A, B,
    input wire clk,
    output wire Y
);
    // 将寄存器从输出移到输入
    reg A_reg, B_reg;
    
    always @(posedge clk) begin
        A_reg <= A;
        B_reg <= B;
    end
    
    // 输出直接使用寄存器后的组合逻辑
    assign Y = A_reg ^ B_reg;
    
endmodule