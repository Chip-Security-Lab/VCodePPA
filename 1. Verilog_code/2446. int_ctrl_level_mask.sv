module int_ctrl_level_mask #(N=4) (
    input clk, rst_n,
    input [N-1:0] int_in,
    input [N-1:0] mask_reg,
    output reg [N-1:0] int_out
);
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) int_out <= 0;
    else int_out <= int_in & mask_reg;
end
endmodule