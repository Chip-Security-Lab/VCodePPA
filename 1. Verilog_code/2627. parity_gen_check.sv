module parity_gen_check(
  input [7:0] tx_data,
  input rx_parity,
  output tx_parity,
  output error_detected
);
  assign tx_parity = ^tx_data;
  assign error_detected = rx_parity ^ (^tx_data);
endmodule