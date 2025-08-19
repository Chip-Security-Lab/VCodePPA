//SystemVerilog
module polarity_reset_monitor #(
  parameter ACTIVE_HIGH = 1
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg normalized_reset;
  reg [1:0] reset_sync;
  
  // Buffered reset_sync signals to reduce fanout
  reg reset_sync_buf1;
  reg reset_sync_buf2;
  
  // Normalize reset_in signal based on active polarity
  always @(*) begin
    normalized_reset = ACTIVE_HIGH ? reset_in : !reset_in;
  end
  
  // First stage: synchronize external reset
  always @(posedge clk) begin
    reset_sync[0] <= normalized_reset;
  end
  
  // Second stage: complete the synchronization chain
  always @(posedge clk) begin
    reset_sync[1] <= reset_sync[0];
  end
  
  // Create buffered copies to reduce fanout
  always @(posedge clk) begin
    reset_sync_buf1 <= reset_sync[1];
    reset_sync_buf2 <= reset_sync[1];
  end
  
  // Generate reset_out with appropriate polarity
  always @(posedge clk) begin
    reset_out <= ACTIVE_HIGH ? reset_sync_buf1 : !reset_sync_buf2;
  end
endmodule