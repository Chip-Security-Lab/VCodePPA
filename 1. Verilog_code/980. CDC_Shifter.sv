module CDC_Shifter #(parameter WIDTH=8) (
    input src_clk, dst_clk,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
reg [WIDTH-1:0] src_reg, dst_reg;
always @(posedge src_clk) src_reg <= data_in;
always @(posedge dst_clk) dst_reg <= src_reg;
assign data_out = dst_reg;
endmodule