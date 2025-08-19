//SystemVerilog
module AsyncSetLatch #(parameter W=8) (
    input clk, set,
    input [W-1:0] d,
    output reg [W-1:0] q
);
always @(posedge clk or posedge set)
    q <= set ? {W{1'b1}} : d;
endmodule