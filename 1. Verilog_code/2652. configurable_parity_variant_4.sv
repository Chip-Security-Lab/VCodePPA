//SystemVerilog
module configurable_parity #(
    parameter WIDTH = 16
)(
    input clk,
    input cfg_parity_type, // 0: even, 1: odd
    input [WIDTH-1:0] data,
    output reg parity
);
    // 预计算奇偶校验
    wire even_parity = ^data;
    wire odd_parity = ~even_parity;
    
    // 通过多路复用器选择正确的奇偶校验
    always @(posedge clk)
        parity <= cfg_parity_type ? odd_parity : even_parity;
endmodule