//SystemVerilog
module byte_select_parity(
  input [31:0] data_word,
  input [3:0] byte_enable,
  output parity_out
);
  wire [3:0] byte_parity;
  
  // 直接计算每个字节的奇偶校验，并考虑字节使能
  assign byte_parity[0] = byte_enable[0] & ^data_word[7:0];
  assign byte_parity[1] = byte_enable[1] & ^data_word[15:8];
  assign byte_parity[2] = byte_enable[2] & ^data_word[23:16];
  assign byte_parity[3] = byte_enable[3] & ^data_word[31:24];
  
  // 使用两级异或优化最终输出
  assign parity_out = (byte_parity[0] ^ byte_parity[1]) ^ (byte_parity[2] ^ byte_parity[3]);
endmodule