module pl_reg_accum #(parameter W=8) (
    input clk, rst, add_en,
    input [W-1:0] add_val,
    output reg [W-1:0] sum
);
always @(posedge clk or posedge rst)
    if (rst) sum <= 0;
    else if (add_en) sum <= sum + add_val;
endmodule