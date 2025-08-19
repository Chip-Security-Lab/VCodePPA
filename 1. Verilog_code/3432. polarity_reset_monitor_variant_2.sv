//SystemVerilog
module polarity_reset_monitor #(
  parameter ACTIVE_HIGH = 1
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg normalized_reset;
  reg normalized_reset_r;
  reg reset_sync;
  
  // Convert ternary to if-else for normalized_reset
  always @(*) begin
    if (ACTIVE_HIGH) begin
      normalized_reset = reset_in;
    end else begin
      normalized_reset = !reset_in;
    end
  end
  
  always @(posedge clk) begin
    normalized_reset_r <= normalized_reset;
    reset_sync <= normalized_reset_r;
    
    // Convert ternary to if-else for reset_out
    if (ACTIVE_HIGH) begin
      reset_out <= reset_sync;
    end else begin
      reset_out <= !reset_sync;
    end
  end
endmodule