module polarity_conv #(MODE=0)(input [15:0] in, output [15:0] out);
assign out = MODE ? {~in[15], in[14:0]} : in + 32768;
endmodule