//SystemVerilog
module one_hot_arbiter(
  input wire clock, clear,
  input wire enable,
  input wire [7:0] requests,
  output reg [7:0] grants
);
  reg [7:0] priority_mask;
  wire [7:0] masked_requests;
  wire [7:0] first_priority;
  wire [7:0] second_priority;
  wire no_masked_requests;
  
  // Apply mask to requests
  assign masked_requests = requests & ~priority_mask;
  assign no_masked_requests = ~|masked_requests;
  
  // First priority logic - balanced tree structure to reduce delay
  // Level 1: bit-level detection
  wire [3:0] has_masked_req_l1;
  assign has_masked_req_l1[0] = |masked_requests[1:0];
  assign has_masked_req_l1[1] = |masked_requests[3:2];
  assign has_masked_req_l1[2] = |masked_requests[5:4];
  assign has_masked_req_l1[3] = |masked_requests[7:6];
  
  // Level 2: group-level detection
  wire [1:0] has_masked_req_l2;
  assign has_masked_req_l2[0] = |has_masked_req_l1[1:0];
  assign has_masked_req_l2[1] = |has_masked_req_l1[3:2];
  
  // Optimized first priority - break up long logic chains
  assign first_priority[0] = masked_requests[0];
  assign first_priority[1] = masked_requests[1] & ~masked_requests[0];
  
  wire [1:0] mask_01_active = {masked_requests[1], masked_requests[0]};
  assign first_priority[2] = masked_requests[2] & ~(|mask_01_active);
  
  wire [2:0] mask_02_active = {masked_requests[2], mask_01_active};
  assign first_priority[3] = masked_requests[3] & ~(|mask_02_active);
  
  // Use accumulated terms to avoid deep logic chains
  wire mask_03_active = |masked_requests[3:0];
  assign first_priority[4] = masked_requests[4] & ~mask_03_active;
  
  wire mask_04_active = mask_03_active | masked_requests[4];
  assign first_priority[5] = masked_requests[5] & ~mask_04_active;
  
  wire mask_05_active = mask_04_active | masked_requests[5];
  assign first_priority[6] = masked_requests[6] & ~mask_05_active;
  
  wire mask_06_active = mask_05_active | masked_requests[6];
  assign first_priority[7] = masked_requests[7] & ~mask_06_active;
  
  // Second priority logic - same optimization as first priority
  assign second_priority[0] = requests[0];
  assign second_priority[1] = requests[1] & ~requests[0];
  
  wire [1:0] req_01_active = {requests[1], requests[0]};
  assign second_priority[2] = requests[2] & ~(|req_01_active);
  
  wire [2:0] req_02_active = {requests[2], req_01_active};
  assign second_priority[3] = requests[3] & ~(|req_02_active);
  
  // Use accumulated terms to avoid deep logic chains
  wire req_03_active = |requests[3:0];
  assign second_priority[4] = requests[4] & ~req_03_active;
  
  wire req_04_active = req_03_active | requests[4];
  assign second_priority[5] = requests[5] & ~req_04_active;
  
  wire req_05_active = req_04_active | requests[5];
  assign second_priority[6] = requests[6] & ~req_05_active;
  
  wire req_06_active = req_05_active | requests[6];
  assign second_priority[7] = requests[7] & ~req_06_active;
  
  // Precompute next priority mask values to reduce sequential logic delay
  wire [7:0] next_mask_from_first = {first_priority[6:0], first_priority[7]};
  wire [7:0] next_mask_from_second = {second_priority[6:0], second_priority[7]};
  wire [7:0] next_priority_mask = |first_priority ? next_mask_from_first : next_mask_from_second;
  wire [7:0] next_grants = no_masked_requests ? second_priority : first_priority;
  
  always @(posedge clock or posedge clear) begin
    if (clear) begin
      grants <= 8'h00;
      priority_mask <= 8'h01;
    end
    else if (enable) begin
      // Use precomputed values to reduce delay after clock edge
      grants <= next_grants;
      
      // Update priority mask for next cycle if any request was granted
      if (|next_grants) begin
        priority_mask <= next_priority_mask;
      end
    end
  end
endmodule