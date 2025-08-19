//SystemVerilog
module RD7(
  input clk,
  input rst_n_in,
  output rst_n_out
);
  reg r1, r2;
  
  always @(posedge clk or negedge rst_n_in) begin
    r1 <= rst_n_in ? 1'b1 : 1'b0;
    r2 <= rst_n_in ? r1 : 1'b0;
  end
  
  assign rst_n_out = r2;
endmodule