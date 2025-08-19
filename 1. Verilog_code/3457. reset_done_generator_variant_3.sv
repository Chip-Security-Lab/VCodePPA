//SystemVerilog
module reset_done_generator (
  input wire clk,
  input wire reset_n,
  output wire reset_done
);
  reg reset_done_int;
  
  always @(posedge clk) begin
    reset_done_int <= reset_n ? 1'b1 : 1'b0;
  end
  
  assign reset_done = reset_done_int;
endmodule