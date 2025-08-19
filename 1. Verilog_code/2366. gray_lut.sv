module gray_lut #(parameter DEPTH=256, AW=8)(
    input clk, en,
    input [AW-1:0] addr,
    output reg [7:0] gray_out
);
reg [7:0] lut [0:DEPTH-1];
initial $readmemh("gray_table.hex", lut);
always @(posedge clk) begin
    if (en) gray_out <= lut[addr];
end
endmodule
