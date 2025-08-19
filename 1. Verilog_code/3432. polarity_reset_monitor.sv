module polarity_reset_monitor #(
  parameter ACTIVE_HIGH = 1
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  wire normalized_reset = ACTIVE_HIGH ? reset_in : !reset_in;
  reg [1:0] reset_sync;
  
  always @(posedge clk) begin
    reset_sync <= {reset_sync[0], normalized_reset};
    reset_out <= ACTIVE_HIGH ? reset_sync[1] : !reset_sync[1];
  end
endmodule