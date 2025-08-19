module int_ctrl_mask #(
    parameter DW = 16
)(
    input clk, en,
    input [DW-1:0] req_in,
    input [DW-1:0] mask,
    output reg [DW-1:0] masked_req
);
reg [DW-1:0] req_reg;
always @(posedge clk) begin
    if(en) req_reg <= req_in;
    masked_req <= req_reg & ~mask;
end
endmodule