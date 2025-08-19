module pl_reg_bound #(parameter W=8, MAX=8'h7F) (
    input clk, load,
    input [W-1:0] d_in,
    output reg [W-1:0] q
);
always @(posedge clk)
    if (load) q <= (d_in > MAX) ? MAX : d_in;
endmodule