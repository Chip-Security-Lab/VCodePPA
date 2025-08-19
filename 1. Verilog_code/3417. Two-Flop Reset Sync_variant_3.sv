//SystemVerilog
module RD7(
  input clk,
  input rst_n_in,
  output reg rst_n_out
);
  // Backward retiming: Moving register from output toward input to reduce critical path
  // Using conditional operator for more compact reset logic

  always @(posedge clk or negedge rst_n_in)
    rst_n_out <= !rst_n_in ? 1'b0 : 1'b1;
  
endmodule