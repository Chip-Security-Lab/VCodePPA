module int_ctrl_vectored #(VEC_W=16)(
    input clk, rst,
    input [VEC_W-1:0] int_in,
    input [VEC_W-1:0] mask_reg,
    output [VEC_W-1:0] int_out
);
reg [VEC_W-1:0] pending_reg;
always @(posedge clk) begin
    if(rst) pending_reg <= 0;
    else pending_reg <= (pending_reg | int_in) & mask_reg;
end
assign int_out = pending_reg;
endmodule