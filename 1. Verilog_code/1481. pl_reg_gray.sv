module pl_reg_gray #(parameter W=4) (
    input clk, en,
    input [W-1:0] bin_in,
    output reg [W-1:0] gray_out
);
always @(posedge clk)
    if (en) gray_out <= bin_in ^ (bin_in >> 1);
endmodule