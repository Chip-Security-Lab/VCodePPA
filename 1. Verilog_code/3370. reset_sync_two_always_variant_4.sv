//SystemVerilog
module reset_sync_two_always(
  input  wire clk,
  input  wire rst_n,
  output reg  out_rst
);
  
  reg reset_stage1;
  reg rst_n_reg;
  
  // Input register stage
  always @(posedge clk) begin
    rst_n_reg <= rst_n;
  end
  
  // First stage synchronizer
  always @(posedge clk) begin
    if (~rst_n_reg) 
      reset_stage1 <= 1'b0; 
    else 
      reset_stage1 <= 1'b1;
  end
  
  // Second stage synchronizer
  always @(posedge clk) begin
    if (~rst_n_reg) 
      out_rst <= 1'b0; 
    else 
      out_rst <= reset_stage1;
  end
  
endmodule