module dynamic_rounder #(W=16)(input [W+2:0] in, input mode, output [W-1:0] out);
assign out = mode ? in[W+2:3]+(|in[2:0]) : in[W+2:3];
endmodule