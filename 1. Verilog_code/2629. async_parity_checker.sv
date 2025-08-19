module async_parity_checker(
  input [7:0] data_recv,
  input parity_recv,
  output error_flag
);
  wire calculated_parity;
  assign calculated_parity = ^data_recv;
  assign error_flag = calculated_parity ^ parity_recv;
endmodule