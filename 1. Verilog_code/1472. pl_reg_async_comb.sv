module pl_reg_async_comb #(parameter W=4) (
    input clk, arst, load,
    input [W-1:0] din,
    output [W-1:0] dout
);
reg [W-1:0] reg_d;
always @(posedge clk or posedge arst)
    if (arst) reg_d <= 0;
    else if (load) reg_d <= din;
assign dout = reg_d;
endmodule