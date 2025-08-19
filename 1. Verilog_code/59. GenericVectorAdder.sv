module vec_add #(parameter W=6)(
  input [W-1:0] vec1, vec2,
  output [W:0] vec_out
); 
  assign vec_out = vec1 + vec2; //Generic vector addition
endmodule