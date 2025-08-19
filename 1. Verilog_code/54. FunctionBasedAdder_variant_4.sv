//SystemVerilog
module func_adder_top(
  input [4:0] alpha, beta,
  output [5:0] sigma
);

  // 实例化加法器子模块
  adder_core u_adder_core(
    .a(alpha),
    .b(beta),
    .sum(sigma)
  );

endmodule

module adder_core(
  input [4:0] a, b,
  output [5:0] sum
);

  // 使用函数实现加法运算
  function [5:0] add;
    input [4:0] a,b;
    add = a + b;
  endfunction
  
  assign sum = add(a,b);

endmodule