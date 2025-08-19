//SystemVerilog
module byte_select_parity(
  input [31:0] data_word,
  input [3:0] byte_enable,
  output reg parity_out
);
  reg [3:0] byte_parity;
  
  always @(*) begin
    // 计算第一个字节的奇偶校验
    if (byte_enable[0]) 
      byte_parity[0] = ^data_word[7:0];
    else
      byte_parity[0] = 1'b0;
      
    // 计算第二个字节的奇偶校验
    if (byte_enable[1])
      byte_parity[1] = ^data_word[15:8];
    else
      byte_parity[1] = 1'b0;
      
    // 计算第三个字节的奇偶校验
    if (byte_enable[2])
      byte_parity[2] = ^data_word[23:16];
    else
      byte_parity[2] = 1'b0;
      
    // 计算第四个字节的奇偶校验
    if (byte_enable[3])
      byte_parity[3] = ^data_word[31:24];
    else
      byte_parity[3] = 1'b0;
      
    // 计算总体奇偶校验
    parity_out = ^byte_parity;
  end
endmodule