module float_rot #(EXP=5,MANT=10)(input [EXP+MANT:0] in, input [4:0] sh, output [EXP+MANT:0] out);
wire [MANT:0] rot_mant = {in[MANT:0], in[MANT:0]} >> sh;
assign out = {in[EXP+MANT], in[EXP+MANT-1:MANT], rot_mant[MANT:1]};
endmodule
