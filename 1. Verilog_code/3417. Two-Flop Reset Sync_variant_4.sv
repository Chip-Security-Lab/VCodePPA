//SystemVerilog
module RD7(
  input clk,
  input rst_n_in,
  output reg rst_n_out
);
  
  // Applying backward register retiming
  // - Moving registers closer to input to balance paths
  // - Eliminating intermediate registers through retiming
  
  always @(posedge clk)
    rst_n_out <= rst_n_in ? rst_n_in : 1'b0;
  
endmodule