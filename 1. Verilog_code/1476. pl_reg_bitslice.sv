module pl_reg_bitslice #(parameter W=8) (
    input clk, en,
    input [W-1:0] data_in,
    output [W-1:0] data_out
);
reg [W-1:0] data_out_reg;
assign data_out = data_out_reg;

always @(posedge clk) begin
    if (en) data_out_reg <= data_in;
end
endmodule