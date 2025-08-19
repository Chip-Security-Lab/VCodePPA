//SystemVerilog
module lru_arbiter #(parameter CLIENTS=4) (
  input wire clock, reset,
  input wire [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);
  // Parameters for fixed bit width calculations
  localparam LRU_BITS = CLIENTS*2;
  localparam IDX_BITS = $clog2(CLIENTS);
  
  // LRU counters memory
  reg [LRU_BITS-1:0] lru_count [CLIENTS-1:0];
  
  // Pipeline registers
  reg [CLIENTS-1:0] requests_pipe [2:0];  // 3 pipeline stages
  reg valid_request_pipe [2:0];          // Valid flags for each stage
  reg [IDX_BITS-1:0] highest_idx_pipe [2:0]; // Highest priority client index
  reg [LRU_BITS-1:0] highest_count;      // Current highest count value
  
  // LRU comparison look-up table
  reg [IDX_BITS-1:0] priority_idx_lut [2**CLIENTS-1:0];
  reg [CLIENTS-1:0] client_mask [CLIENTS-1:0];
  
  integer i, j;
  
  // Initialize client masks for faster indexing
  initial begin
    for (i = 0; i < CLIENTS; i = i + 1) begin
      client_mask[i] = (1 << i);
    end
  end
  
  // Reset logic for all pipeline stages
  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < 3; i = i + 1) begin
        requests_pipe[i] <= 0;
        valid_request_pipe[i] <= 0;
        highest_idx_pipe[i] <= 0;
      end
      
      highest_count <= 0;
      grants <= 0;
      
      for (i = 0; i < CLIENTS; i = i + 1)
        lru_count[i] <= 0;
    end
  end
  
  // Stage 1: Request registration and counter updates
  always @(posedge clock) begin
    if (!reset) begin
      // Pipeline registers update
      requests_pipe[0] <= requests;
      valid_request_pipe[0] <= |requests;
      
      // Update all LRU counters
      for (i = 0; i < CLIENTS; i = i + 1)
        lru_count[i] <= lru_count[i] + 1;
    end
  end
  
  // LRU priority determination logic using look-up approach
  always @(*) begin
    highest_count = 0;
    highest_idx_pipe[0] = 0;
    
    for (i = 0; i < CLIENTS; i = i + 1) begin
      if (requests_pipe[0][i] && (lru_count[i] > highest_count)) begin
        highest_count = lru_count[i];
        highest_idx_pipe[0] = i;
      end
    end
  end
  
  // Stage 2: Data propagation to middle stage
  always @(posedge clock) begin
    if (!reset) begin
      requests_pipe[1] <= requests_pipe[0];
      highest_idx_pipe[1] <= highest_idx_pipe[0];
      valid_request_pipe[1] <= valid_request_pipe[0];
    end
  end
  
  // Stage 3: Data propagation to final stage
  always @(posedge clock) begin
    if (!reset) begin
      requests_pipe[2] <= requests_pipe[1];
      highest_idx_pipe[2] <= highest_idx_pipe[1];
      valid_request_pipe[2] <= valid_request_pipe[1];
    end
  end
  
  // Grant generation using one-hot encoding lookup
  always @(posedge clock) begin
    if (!reset) begin
      grants <= 0;
      
      if (valid_request_pipe[2]) begin
        // Use the lookup table to generate grants
        grants <= client_mask[highest_idx_pipe[2]];
        
        // Reset the winner's counter
        lru_count[highest_idx_pipe[2]] <= 0;
      end
    end
  end
endmodule