//SystemVerilog
// 顶层模块
module multi_bit_parity (
  input  [15:0] data_word,
  output [1:0]  parity_bits
);
  
  // 低8位奇偶校验计算
  parity_calculator #(
    .WIDTH(8)
  ) low_byte_parity (
    .data_in  (data_word[7:0]),
    .parity   (parity_bits[0])
  );
  
  // 高8位奇偶校验计算
  parity_calculator #(
    .WIDTH(8)
  ) high_byte_parity (
    .data_in  (data_word[15:8]),
    .parity   (parity_bits[1])
  );
  
endmodule

// 可参数化的奇偶校验计算子模块
module parity_calculator #(
  parameter WIDTH = 8
)(
  input  [WIDTH-1:0] data_in,
  output             parity
);
  
  // 计算指定宽度数据的奇偶校验位
  assign parity = ^data_in;
  
endmodule