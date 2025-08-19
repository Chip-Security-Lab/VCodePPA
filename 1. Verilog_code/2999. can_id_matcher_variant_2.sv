//SystemVerilog
module can_id_matcher #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output reg id_match,
  output reg [NUM_PATTERNS-1:0] pattern_matched,
  output reg [7:0] match_index
);
  integer i;
  wire [NUM_PATTERNS-1:0] pattern_match_results;
  reg [NUM_PATTERNS-1:0] match_detected;
  reg id_match_found;
  reg [7:0] detected_index;
  
  // Generate comparison results using Kogge-Stone based equality checkers
  genvar g;
  generate
    for (g = 0; g < NUM_PATTERNS; g = g + 1) begin: match_gen
      wire id_equal;
      ks_equality_checker #(
        .WIDTH(11)
      ) id_compare (
        .a(rx_id),
        .b(match_patterns[g]),
        .equal(id_equal)
      );
      
      assign pattern_match_results[g] = pattern_enable[g] & id_equal;
    end
  endgenerate
  
  // First always block: Match detection combinational logic
  always @(*) begin
    match_detected = 0;
    id_match_found = 0;
    detected_index = 0;
    
    for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
      if (pattern_match_results[i] && !id_match_found) begin
        match_detected[i] = 1;
        id_match_found = 1;
        detected_index = i;
      end
    end
  end
  
  // Second always block: Reset handling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end
    else begin
      // Third always block functionality merged here for reset consistency
      if (id_valid) begin
        id_match <= id_match_found;
        pattern_matched <= match_detected;
        match_index <= detected_index;
      end
      else begin
        id_match <= id_match;
        pattern_matched <= pattern_matched;
        match_index <= match_index;
      end
    end
  end
endmodule

// Kogge-Stone based equality checker
module ks_equality_checker #(
  parameter WIDTH = 11
)(
  input wire [WIDTH-1:0] a,
  input wire [WIDTH-1:0] b,
  output wire equal
);
  // Generate XNOR for bit-by-bit equality
  wire [WIDTH-1:0] bit_equal;
  
  // Split the equality generation into a separate block
  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: xnor_gen
      assign bit_equal[i] = ~(a[i] ^ b[i]);
    end
  endgenerate
  
  // Kogge-Stone parallel prefix for AND reduction
  // Split into separate wires for each stage
  wire [WIDTH-1:0] stage1, stage2, stage3, stage4;
  
  // Stage 1: span 1
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: stage1_gen
      if (i == 0)
        assign stage1[i] = bit_equal[i];
      else
        assign stage1[i] = bit_equal[i] & bit_equal[i-1];
    end
  endgenerate
  
  // Stage 2: span 2
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: stage2_gen
      if (i < 2)
        assign stage2[i] = stage1[i];
      else
        assign stage2[i] = stage1[i] & stage1[i-2];
    end
  endgenerate
  
  // Stage 3: span 4
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: stage3_gen
      if (i < 4)
        assign stage3[i] = stage2[i];
      else
        assign stage3[i] = stage2[i] & stage2[i-4];
    end
  endgenerate
  
  // Stage 4: span 8
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin: stage4_gen
      if (i < 8)
        assign stage4[i] = stage3[i];
      else
        assign stage4[i] = stage3[i] & stage3[i-8];
    end
  endgenerate
  
  // Final result is the last bit of the last stage
  assign equal = stage4[WIDTH-1];
endmodule