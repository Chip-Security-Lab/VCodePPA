//SystemVerilog
// 顶层模块
module parity_with_error_injection(
  input [15:0] data_in,
  input error_inject,
  output parity
);

  // 实例化子模块
  wire parity_result;
  wire error_injected_data;

  // 计算奇偶校验子模块
  parity_calculator parity_calc (
    .data_in(data_in),
    .parity(parity_result)
  );

  // 错误注入子模块
  error_injector error_inj (
    .data_in(data_in),
    .error_inject(error_inject),
    .data_out(error_injected_data)
  );

  // 计算最终奇偶校验
  assign parity = parity_result ^ error_injected_data;

endmodule

// 奇偶校验计算子模块
module parity_calculator(
  input [15:0] data_in,
  output parity
);
  assign parity = ^data_in; // 计算输入数据的奇偶校验
endmodule

// 错误注入子模块
module error_injector(
  input [15:0] data_in,
  input error_inject,
  output [15:0] data_out
);
  assign data_out = data_in ^ {16{error_inject}}; // 根据错误注入信号注入错误
endmodule