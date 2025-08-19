module reverse_add(
  input [0:3] vectorA,  //MSB first
  input [0:3] vectorB,
  output [0:4] result
);
  assign result = vectorA + vectorB; //Non-standard indexing
endmodule