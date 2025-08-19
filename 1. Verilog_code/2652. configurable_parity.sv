module configurable_parity #(
    parameter WIDTH = 16
)(
    input clk,
    input cfg_parity_type, // 0: even, 1: odd
    input [WIDTH-1:0] data,
    output reg parity
);
wire calc_parity = ^data;
always @(posedge clk)
    parity <= cfg_parity_type ? calc_parity : ~calc_parity;
endmodule