//SystemVerilog
module parity_gen_check(
  input [7:0] tx_data,
  input rx_parity,
  output tx_parity,
  output error_detected
);
  wire data_parity = tx_data[0] ^ tx_data[1] ^ tx_data[2] ^ tx_data[3] ^ 
                    tx_data[4] ^ tx_data[5] ^ tx_data[6] ^ tx_data[7];
  
  assign tx_parity = data_parity;
  assign error_detected = rx_parity ^ data_parity;
endmodule