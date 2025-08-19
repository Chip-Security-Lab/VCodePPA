//SystemVerilog
module reset_sync_two_always (
  input  wire clk,          // System clock
  input  wire rst_n,        // Asynchronous active-low reset
  output reg  reset_synced  // Synchronized reset output
);
  
  // Reset synchronization pipeline registers
  // Each stage contributes to metastability resolution
  reg reset_sync_stage1;    // First synchronization stage
  reg reset_sync_stage2;    // Second synchronization stage
  reg reset_sync_stage3;    // Third synchronization stage
  
  // Reset synchronization pipeline - implemented as a single process for clarity
  // This creates a clear data flow path from async input to synchronized output
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Asynchronous reset assertion - clear all stages
      reset_sync_stage1 <= 1'b0;
      reset_sync_stage2 <= 1'b0;
      reset_sync_stage3 <= 1'b0;
      reset_synced     <= 1'b0;
    end else begin
      // Normal synchronization pipeline flow
      // Data flows from stage 1 to output with controlled timing
      reset_sync_stage1 <= 1'b1;
      reset_sync_stage2 <= reset_sync_stage1;
      reset_sync_stage3 <= reset_sync_stage2;
      reset_synced     <= reset_sync_stage3;
    end
  end
  
endmodule