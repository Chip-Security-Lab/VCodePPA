//SystemVerilog
`timescale 1ns / 1ps
module d_latch (
    input  wire enable,
    input  wire d,
    output reg  q
);
    // 优化的锁存器实现
    always @(enable or d) begin
        if (enable)
            q = d;
    end
endmodule