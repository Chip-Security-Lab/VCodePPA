module pl_reg_init #(parameter W=8, INIT=0) (
    input clk, init,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
always @(posedge clk)
    data_out <= init ? INIT : data_in;
endmodule