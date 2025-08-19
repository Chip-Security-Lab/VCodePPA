module signmag_conv(input signed [15:0] in, output [15:0] out);
assign out = {in[15], in[14:0] ^ {15{in[15]}}};
endmodule