//SystemVerilog
module polarity_reset_monitor #(
  parameter ACTIVE_HIGH = 1
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  
  // Directly normalize the input reset signal
  wire normalized_reset_input = ACTIVE_HIGH ? reset_in : !reset_in;
  
  // First register stage (moved after normalization logic)
  reg normalized_reset_reg;
  
  always @(posedge clk) begin
    normalized_reset_reg <= normalized_reset_input;
  end
  
  // Second register stage
  reg normalized_reset_sync;
  
  always @(posedge clk) begin
    normalized_reset_sync <= normalized_reset_reg;
    reset_out <= ACTIVE_HIGH ? normalized_reset_sync : !normalized_reset_sync;
  end
endmodule