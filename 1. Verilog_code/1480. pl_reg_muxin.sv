module pl_reg_muxin #(parameter W=4) (
    input clk, sel,
    input [W-1:0] d0, d1,
    output reg [W-1:0] q
);
always @(posedge clk)
    q <= sel ? d1 : d0;
endmodule