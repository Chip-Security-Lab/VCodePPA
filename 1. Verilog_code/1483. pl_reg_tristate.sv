module pl_reg_tristate #(parameter W=8) (
    input clk, oe, load,
    input [W-1:0] d,
    output [W-1:0] q
);
reg [W-1:0] data_reg;
always @(posedge clk)
    if (load) data_reg <= d;
assign q = oe ? data_reg : {W{1'bz}};
endmodule