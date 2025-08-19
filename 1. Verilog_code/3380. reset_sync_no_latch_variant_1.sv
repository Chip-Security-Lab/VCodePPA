//SystemVerilog
//========================================================================
// Top Level Module: Reset Synchronizer System
//========================================================================
module reset_sync_system #(
  parameter SYNC_STAGES = 2  // Parameterized number of synchronization stages
)(
  input  wire clk,           // System clock
  input  wire rst_n,         // Asynchronous reset, active low
  output wire synced_rst_n   // Synchronized reset output, active low
);

  // Internal synchronization chain signals
  wire [SYNC_STAGES:0] sync_chain;
  
  // Input to the sync chain is the external reset
  assign sync_chain[0] = rst_n;
  
  // Generate multiple synchronization stages
  genvar i;
  generate
    for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_stage
      reset_sync_stage u_sync_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .stage_in   (sync_chain[i]),
        .stage_out  (sync_chain[i+1])
      );
    end
  endgenerate
  
  // Final synchronized output
  assign synced_rst_n = sync_chain[SYNC_STAGES];
  
endmodule

//========================================================================
// Reset Synchronization Stage
// Implements a single stage of reset synchronization
//========================================================================
module reset_sync_stage (
  input  wire clk,          // System clock
  input  wire rst_n,        // Asynchronous reset, active low
  input  wire stage_in,     // Input from previous stage
  output reg  stage_out     // Output to next stage
);
  
  // Reset synchronization flip-flop
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      stage_out <= 1'b0;   // Force to known state on reset
    end else begin
      stage_out <= stage_in; // Normal synchronization path
    end
  end
  
endmodule

//========================================================================
// Legacy Module Interface for Backward Compatibility
// Maintains the original interface while using the new architecture
//========================================================================
module reset_sync_no_latch (
  input  wire clk,
  input  wire rst_n,
  output wire synced
);

  // Instantiate the parameterized reset synchronizer with 2 stages
  reset_sync_system #(
    .SYNC_STAGES(2)
  ) u_reset_sync_system (
    .clk          (clk),
    .rst_n        (rst_n),
    .synced_rst_n (synced)
  );

endmodule