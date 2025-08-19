module gamma_corr #(DEPTH=256)(input [7:0] in, output [7:0] out);
reg [7:0] lut [0:DEPTH-1]; initial $readmemh("gamma_lut.hex", lut);
assign out = lut[in];
endmodule