//SystemVerilog

// 子模块1: 二进制异或计算
module xor_calculator(
  input [7:0] data,
  output [3:0] xor_level1
);
  assign xor_level1 = {data[7] ^ data[6], data[5] ^ data[4],
                       data[3] ^ data[2], data[1] ^ data[0]};
endmodule

// 子模块2: 二进制异或汇总
module xor_reducer(
  input [3:0] xor_input,
  output parity_calc
);
  wire [1:0] xor_level2;
  assign xor_level2 = {xor_input[3] ^ xor_input[2], xor_input[1] ^ xor_input[0]};
  assign parity_calc = xor_level2[1] ^ xor_level2[0];
endmodule

// 顶层模块: 异步奇偶校验检查器
module async_parity_checker(
  input [7:0] data_recv,
  input parity_recv,
  output error_flag
);
  wire [3:0] xor_level1;
  wire parity_calc;

  // 实例化子模块
  xor_calculator u_xor_calculator (
    .data(data_recv),
    .xor_level1(xor_level1)
  );

  xor_reducer u_xor_reducer (
    .xor_input(xor_level1),
    .parity_calc(parity_calc)
  );

  assign error_flag = parity_calc ^ parity_recv;
endmodule