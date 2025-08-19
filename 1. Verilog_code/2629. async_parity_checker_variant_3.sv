//SystemVerilog
module async_parity_checker(
  input [7:0] data_recv,
  input parity_recv,
  output error_flag
);
  // 计算data_recv的奇偶性，并与接收到的奇偶位比较
  // 使用异或链而不是归约异或操作符
  wire parity_calc;
  assign parity_calc = data_recv[0] ^ data_recv[1] ^ data_recv[2] ^ data_recv[3] ^ 
                       data_recv[4] ^ data_recv[5] ^ data_recv[6] ^ data_recv[7];
  
  // 最终错误检测逻辑
  assign error_flag = parity_calc ^ parity_recv;
endmodule