module func_adder(
  input [4:0] alpha, beta,
  output [5:0] sigma
);
  function [5:0] add;
    input [4:0] a,b;
    add = a + b;
  endfunction
  
  assign sigma = add(alpha,beta); //Using function
endmodule