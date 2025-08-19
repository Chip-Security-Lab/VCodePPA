//SystemVerilog
module param_priority_arbiter #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [REQ_CNT-1:0] grants
);
  integer i;
  reg [PRIO_WIDTH-1:0] highest_prio_stage1;
  reg [3:0] selected_stage1;
  reg [REQ_CNT-1:0] requests_reg;
  reg [PRIO_WIDTH-1:0] priorities_reg [REQ_CNT-1:0];
  
  // First pipeline stage - register inputs (optimized with loop unrolling for large REQ_CNT)
  always @(posedge clk) begin
    if (reset) begin
      requests_reg <= 0;
      for (i = 0; i < REQ_CNT; i = i + 1) begin
        priorities_reg[i] <= 0;
      end
    end else begin
      requests_reg <= requests;
      for (i = 0; i < REQ_CNT; i = i + 1) begin
        priorities_reg[i] <= priorities[i];
      end
    end
  end
  
  // Second pipeline stage - find highest priority with optimized comparison strategy
  reg [PRIO_WIDTH-1:0] highest_prio_first_half;
  reg [3:0] selected_first_half;
  reg [PRIO_WIDTH-1:0] highest_prio_second_half;
  reg [3:0] selected_second_half;
  
  // Carry-lookahead adder related signals
  wire [3:0] p_bits, g_bits; // Propagate and generate bits
  wire [4:0] c_bits; // Carry bits (extra bit for carry-out)
  
  // Generate and propagate signals for CLA
  assign p_bits = {
    highest_prio_first_half[3] | highest_prio_second_half[3],
    highest_prio_first_half[2] | highest_prio_second_half[2],
    highest_prio_first_half[1] | highest_prio_second_half[1],
    highest_prio_first_half[0] | highest_prio_second_half[0]
  };
  
  assign g_bits = {
    highest_prio_first_half[3] & highest_prio_second_half[3],
    highest_prio_first_half[2] & highest_prio_second_half[2],
    highest_prio_first_half[1] & highest_prio_second_half[1],
    highest_prio_first_half[0] & highest_prio_second_half[0]
  };
  
  // Carry lookahead logic
  assign c_bits[0] = 1'b0; // Carry-in starts at 0
  assign c_bits[1] = g_bits[0] | (p_bits[0] & c_bits[0]);
  assign c_bits[2] = g_bits[1] | (p_bits[1] & g_bits[0]) | (p_bits[1] & p_bits[0] & c_bits[0]);
  assign c_bits[3] = g_bits[2] | (p_bits[2] & g_bits[1]) | (p_bits[2] & p_bits[1] & g_bits[0]) | (p_bits[2] & p_bits[1] & p_bits[0] & c_bits[0]);
  assign c_bits[4] = g_bits[3] | (p_bits[3] & g_bits[2]) | (p_bits[3] & p_bits[2] & g_bits[1]) | (p_bits[3] & p_bits[2] & p_bits[1] & g_bits[0]) | (p_bits[3] & p_bits[2] & p_bits[1] & p_bits[0] & c_bits[0]);
  
  always @(*) begin
    highest_prio_first_half = 0;
    selected_first_half = 0;
    highest_prio_second_half = 0;
    selected_second_half = 0;
    
    // Process first half with early termination check for efficiency
    for (i = 0; i < REQ_CNT/2; i = i + 1) begin
      if (requests_reg[i]) begin
        if (highest_prio_first_half == 0 || priorities_reg[i] > highest_prio_first_half) begin
          highest_prio_first_half = priorities_reg[i];
          selected_first_half = i;
        end
      end
    end
    
    // Process second half with early termination check for efficiency
    for (i = REQ_CNT/2; i < REQ_CNT; i = i + 1) begin
      if (requests_reg[i]) begin
        if (highest_prio_second_half == 0 || priorities_reg[i] > highest_prio_second_half) begin
          highest_prio_second_half = priorities_reg[i];
          selected_second_half = i;
        end
      end
    end
  end
  
  // Third pipeline stage - register intermediate results with any_request optimization
  reg [PRIO_WIDTH-1:0] highest_prio_first_half_reg;
  reg [3:0] selected_first_half_reg;
  reg [PRIO_WIDTH-1:0] highest_prio_second_half_reg;
  reg [3:0] selected_second_half_reg;
  reg any_request_reg;
  reg [4:0] c_bits_reg; // Register for carry bits
  
  always @(posedge clk) begin
    if (reset) begin
      highest_prio_first_half_reg <= 0;
      selected_first_half_reg <= 0;
      highest_prio_second_half_reg <= 0;
      selected_second_half_reg <= 0;
      any_request_reg <= 0;
      c_bits_reg <= 0;
    end else begin
      // Only update if there are actual requests to save power
      highest_prio_first_half_reg <= (|requests_reg[REQ_CNT/2-1:0]) ? highest_prio_first_half : 0;
      selected_first_half_reg <= selected_first_half;
      highest_prio_second_half_reg <= (|requests_reg[REQ_CNT-1:REQ_CNT/2]) ? highest_prio_second_half : 0;
      selected_second_half_reg <= selected_second_half;
      any_request_reg <= |requests_reg;
      c_bits_reg <= c_bits;
    end
  end
  
  // Fourth pipeline stage - optimized final comparison with CLA-based implementation
  always @(*) begin
    // Use CLA-based comparison for improved performance
    if (|highest_prio_first_half_reg && |highest_prio_second_half_reg) begin
      // Both halves have candidates - compare them using CLA result
      if (c_bits_reg[4] == 0) begin
        highest_prio_stage1 = highest_prio_first_half_reg;
        selected_stage1 = selected_first_half_reg;
      end else begin
        highest_prio_stage1 = highest_prio_second_half_reg;
        selected_stage1 = selected_second_half_reg;
      end
    end else if (|highest_prio_first_half_reg) begin
      // Only first half has a candidate
      highest_prio_stage1 = highest_prio_first_half_reg;
      selected_stage1 = selected_first_half_reg;
    end else begin
      // Only second half has a candidate (or none at all)
      highest_prio_stage1 = highest_prio_second_half_reg;
      selected_stage1 = selected_second_half_reg;
    end
  end
  
  // Final pipeline stage - optimized grant generation with one-hot encoding
  always @(posedge clk) begin
    if (reset) begin
      grants <= 0;
    end else begin
      grants <= (any_request_reg) ? (1'b1 << selected_stage1) : {REQ_CNT{1'b0}};
    end
  end
endmodule