module float_lerp #(MANT=10, EXP=5)(input [MANT+EXP:0] a,b, input [7:0] t, output [MANT+EXP:0] c);
wire [MANT*2+1:0] prod = a*(256-t) + b*t;
assign c = prod >> 8;
endmodule