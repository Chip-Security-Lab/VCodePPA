module sd2twos #(W=8)(input [W-1:0] sd, output [W:0] twos);
assign twos = sd + {sd[W-1],{W-1{1'b0}}};
endmodule