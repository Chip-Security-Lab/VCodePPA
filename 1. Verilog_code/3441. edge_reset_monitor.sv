module edge_reset_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_edge_detected
);
  reg reset_n_prev;
  
  always @(posedge clk) begin
    reset_n_prev <= reset_n;
    reset_edge_detected <= ~reset_n & reset_n_prev;
  end
endmodule