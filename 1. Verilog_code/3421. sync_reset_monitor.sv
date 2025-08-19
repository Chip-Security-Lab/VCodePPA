module sync_reset_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stable
);
  reg [2:0] reset_shift;
  
  always @(posedge clk) begin
    reset_shift <= {reset_shift[1:0], reset_n};
    reset_stable <= &reset_shift;
  end
endmodule