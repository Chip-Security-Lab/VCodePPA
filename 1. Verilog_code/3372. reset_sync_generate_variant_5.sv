//SystemVerilog
//==============================================================================
// Module: reset_sync_generate
// Description: Reset synchronization module with configurable pipeline stages
//              with fanout buffering for improved timing performance
// Standard: IEEE 1364-2005
//==============================================================================
module reset_sync_generate #(
  parameter NUM_STAGES = 2  // Number of synchronization stages
)(
  input  wire clk,          // System clock
  input  wire rst_n,        // Asynchronous active-low reset
  output wire synced        // Synchronized reset output
);

  // Reset synchronization pipeline registers with optimized placement
  (* ASYNC_REG = "TRUE" *)  // Synthesis attribute to ensure proper async flop placement
  reg [NUM_STAGES-1:0] sync_chain;
  
  // Pre-registered signal for improved timing
  reg rst_n_pre;
  
  // First stage pre-registration to reduce input-to-register delay
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rst_n_pre <= 1'b0;
    else
      rst_n_pre <= 1'b1;
  end
  
  // First stage handling with registered input
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      sync_chain[0] <= 1'b0;
    else
      sync_chain[0] <= rst_n_pre;
  end

  // Buffer registers with optimized logic connection
  reg [NUM_STAGES-1:0] sync_chain_buf;
  
  // Single optimized buffer register to reduce area and improve timing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      sync_chain_buf <= {NUM_STAGES{1'b0}};
    else
      sync_chain_buf <= sync_chain;
  end

  // Generate remaining synchronization stages with optimized pipeline
  genvar i;
  generate
    for (i = 1; i < NUM_STAGES; i = i + 1) begin : sync_stage
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
          sync_chain[i] <= 1'b0;
        else
          sync_chain[i] <= sync_chain_buf[i-1];
      end
    end
  endgenerate

  // Final synchronized output
  assign synced = sync_chain[NUM_STAGES-1];

endmodule