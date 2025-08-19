module pl_reg_sync #(parameter W=8) (
    input clk, rst_n, en,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
always @(posedge clk)
    if (!rst_n) data_out <= 0;
    else if (en) data_out <= data_in;
endmodule