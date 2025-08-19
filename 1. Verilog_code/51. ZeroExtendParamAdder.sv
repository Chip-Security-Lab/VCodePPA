module cat_add #(parameter N=4)(
  input [N-1:0] in1, in2,
  output [N:0] out
);
  assign out = {1'b0,in1} + {1'b0,in2}; //Zero-extended add
endmodule