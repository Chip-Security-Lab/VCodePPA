module reset_history_monitor (
  input wire clk,
  input wire reset_in,
  input wire clear,
  output reg [7:0] reset_history
);
  reg reset_in_d;
  
  always @(posedge clk) begin
    reset_in_d <= reset_in;
    if (clear)
      reset_history <= 8'h00;
    else if (reset_in && !reset_in_d)
      reset_history <= {reset_history[6:0], 1'b1};
  end
endmodule