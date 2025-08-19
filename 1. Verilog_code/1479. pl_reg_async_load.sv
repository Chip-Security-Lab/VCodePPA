module pl_reg_async_load #(parameter W=8) (
    input clk, rst_n, load,
    input [W-1:0] async_data,
    output reg [W-1:0] q
);
always @(posedge clk or negedge rst_n or posedge load)
    if (!rst_n) q <= 0;
    else if (load) q <= async_data;
endmodule