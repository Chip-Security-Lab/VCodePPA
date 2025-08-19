module exp_map #(W=16)(input [W-1:0] x, output [W-1:0] y);
assign y = (1 << x[W-1:4]) + (x[3:0] << (x[W-1:4]-4));
endmodule