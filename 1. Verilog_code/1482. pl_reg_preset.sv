module pl_reg_preset #(parameter W=8, PRESET=8'hFF) (
    input clk, load, shift_in,
    output reg [W-1:0] q
);
always @(posedge clk)
    q <= load ? PRESET : {q[W-2:0], shift_in};
endmodule