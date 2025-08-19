//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: dual_clock_reset_sync_top.v
// Description: Top module for dual clock reset synchronization
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module dual_clock_reset_sync (
  input  wire clk_a,
  input  wire clk_b,
  input  wire reset_in,
  output wire reset_a,
  output wire reset_b
);

  // Instantiation of synchronizer for clock domain A
  reset_synchronizer #(
    .SYNC_STAGES(3)
  ) sync_domain_a (
    .clk        (clk_a),
    .async_reset(reset_in),
    .sync_reset (reset_a)
  );
  
  // Instantiation of synchronizer for clock domain B
  reset_synchronizer #(
    .SYNC_STAGES(3)
  ) sync_domain_b (
    .clk        (clk_b),
    .async_reset(reset_in),
    .sync_reset (reset_b)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// File: reset_synchronizer.v
// Description: Generic reset synchronizer for any clock domain
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module reset_synchronizer #(
  parameter SYNC_STAGES = 3 // Configurable number of synchronization stages
)(
  input  wire clk,          // Target clock domain
  input  wire async_reset,  // Asynchronous reset input
  output wire sync_reset    // Synchronized reset output
);

  // Pre-register the input reset signal to reduce input to register delay
  reg async_reset_registered;
  
  // Synchronization flip-flop chain with reduced stages
  reg [SYNC_STAGES-2:0] sync_chain;
  
  // First register stage - captures the async input
  always @(posedge clk) begin
    async_reset_registered <= async_reset;
  end
  
  // Synchronization chain - now has one less stage since we pre-registered
  always @(posedge clk or posedge async_reset) begin
    if (async_reset)
      sync_chain <= {(SYNC_STAGES-1){1'b1}}; // Reset all flip-flops to '1'
    else
      sync_chain <= {sync_chain[SYNC_STAGES-3:0], async_reset_registered}; // Shift in registered reset
  end
  
  // Output is the last bit in the synchronization chain
  assign sync_reset = sync_chain[SYNC_STAGES-2];

endmodule