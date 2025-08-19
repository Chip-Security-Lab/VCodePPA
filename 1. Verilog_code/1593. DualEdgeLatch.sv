module DualEdgeLatch #(parameter DW=16) (
    input clk, 
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
always @(clk) dout <= din; // Verilog-2001特性
endmodule