//SystemVerilog
`timescale 1ns / 1ps
module neg_edge_shifter #(parameter LENGTH = 6) (
    input wire neg_clk,
    input wire d_in,
    input wire rstn,
    output wire [LENGTH-1:0] q_out
);
    reg [LENGTH-1:0] shift_reg;
    
    // 实现负边沿触发的移位寄存器，并使用了不同的移位方式
    // 通过位拼接实现左移，d_in放在最低位而不是最高位
    always @(negedge neg_clk or negedge rstn) begin
        shift_reg <= (!rstn) ? {LENGTH{1'b0}} : {shift_reg[LENGTH-2:0], d_in};
    end
    
    // 使用位翻转来实现输出，这相当于对移位结果取补(类似二进制补码原理)
    // 然后再取反，最终实现了与原始功能等效的操作
    assign q_out = ~(~shift_reg);
endmodule