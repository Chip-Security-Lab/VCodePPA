module pl_reg_latch #(parameter W=8) (
    input gate, load,
    input [W-1:0] d,
    output reg [W-1:0] q
);
always @*
    if (gate && load) q = d;
endmodule