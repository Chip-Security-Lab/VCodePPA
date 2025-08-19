//SystemVerilog
module lru_arbiter #(parameter CLIENTS=4) (
  input wire clock,
  input wire reset,
  input wire [CLIENTS-1:0] requests,
  input wire ready_in,
  output reg [CLIENTS-1:0] grants,
  output reg valid_out
);
  // Pre-computation signals for earlier decision making
  reg [CLIENTS*2-1:0] lru_count [CLIENTS-1:0];
  wire [CLIENTS*2-1:0] next_lru_count [CLIENTS-1:0];
  reg [CLIENTS-1:0] requests_stage1;
  reg valid_stage1;
  
  // Moved selection logic earlier in pipeline
  reg [7:0] highest_count;
  reg [$clog2(CLIENTS)-1:0] highest_idx;
  
  // Stage 2 registers
  reg [$clog2(CLIENTS)-1:0] selected_idx_stage2;
  reg valid_stage2;
  
  // Pipeline control signals
  wire stall = valid_out && !ready_in;
  
  // Calculate next LRU count values combinationally
  genvar g;
  generate
    for (g = 0; g < CLIENTS; g = g + 1) begin : next_count_gen
      assign next_lru_count[g] = (valid_stage1 && (highest_idx == g) && requests_stage1[g]) ? 
                                 {CLIENTS*2{1'b0}} : lru_count[g] + 1;
    end
  endgenerate
  
  // Stage 1: Capture requests and pre-compute priority in same cycle
  integer i;
  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < CLIENTS; i = i + 1) lru_count[i] <= 0;
      requests_stage1 <= 0;
      valid_stage1 <= 0;
      highest_count <= 0;
      highest_idx <= 0;
    end else if (!stall) begin
      requests_stage1 <= requests;
      valid_stage1 <= |requests;
      
      // Update LRU counts based on previous cycle's grant
      for (i = 0; i < CLIENTS; i = i + 1) begin
        lru_count[i] <= next_lru_count[i];
      end
      
      // Pre-compute highest priority in same cycle
      highest_count <= 0;
      highest_idx <= 0;
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && lru_count[i] > highest_count) begin
          highest_count <= lru_count[i];
          highest_idx <= i;
        end
      end
    end
  end
  
  // Stage 2: Just pass the pre-computed selection
  always @(posedge clock) begin
    if (reset) begin
      selected_idx_stage2 <= 0;
      valid_stage2 <= 0;
    end else if (!stall) begin
      selected_idx_stage2 <= highest_idx;
      valid_stage2 <= valid_stage1 && |requests_stage1;
    end
  end
  
  // Output stage: Generate grants
  always @(posedge clock) begin
    if (reset) begin
      grants <= 0;
      valid_out <= 0;
    end else if (!stall) begin
      grants <= 0;
      valid_out <= valid_stage2;
      
      if (valid_stage2) begin
        grants[selected_idx_stage2] <= 1'b1;
      end
    end
  end
endmodule