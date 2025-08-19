module dither_trunc #(W=16)(input [W+3:0] in, output [W-1:0] out);
reg [2:0] lfsr=3'b101; always @(in) lfsr <= {lfsr[1:0], lfsr[2]^lfsr[1]};
assign out = in[W+3:4] + (in[3:0] > lfsr);
endmodule
