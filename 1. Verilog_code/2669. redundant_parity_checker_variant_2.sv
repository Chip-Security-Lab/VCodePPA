//SystemVerilog
module redundant_parity_checker(
  input [7:0] data_in,
  input ext_parity,
  output error_detected
);
  wire internal_parity;
  
  // Optimized parity calculation using reduction XOR operation
  assign internal_parity = ^data_in;
  
  // Optimized comparison using XOR for more efficient hardware implementation
  // This produces the same result as inequality comparison but maps better to FPGA/ASIC resources
  assign error_detected = internal_parity ^ ext_parity;
endmodule