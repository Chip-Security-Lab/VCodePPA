module pl_reg_parity #(parameter W=8) (
    input clk, load,
    input [W-1:0] data_in,
    output reg [W:0] data_out
);
always @(posedge clk)
    if (load) data_out <= {^data_in, data_in};
endmodule