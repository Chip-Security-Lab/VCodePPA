//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: can_id_matcher_top.v
// Description: Top-level CAN ID matcher with hierarchical submodules
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module can_id_matcher_top #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire [10:0] rx_id,
  input wire id_valid,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output wire id_match,
  output wire [NUM_PATTERNS-1:0] pattern_matched,
  output wire [7:0] match_index
);

  // Internal signals for pattern comparison results
  wire [NUM_PATTERNS-1:0] pattern_match_results;
  
  // Instantiate pattern comparator module
  pattern_comparator #(
    .NUM_PATTERNS(NUM_PATTERNS)
  ) pattern_comp_inst (
    .rx_id(rx_id),
    .match_patterns(match_patterns),
    .pattern_enable(pattern_enable),
    .pattern_match_results(pattern_match_results)
  );

  // Instantiate match encoder module
  match_encoder #(
    .NUM_PATTERNS(NUM_PATTERNS)
  ) match_enc_inst (
    .clk(clk),
    .rst_n(rst_n),
    .id_valid(id_valid),
    .pattern_match_results(pattern_match_results),
    .id_match(id_match),
    .pattern_matched(pattern_matched),
    .match_index(match_index)
  );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Pattern Comparator Module
// Handles the comparison of incoming ID against all patterns
///////////////////////////////////////////////////////////////////////////////

module pattern_comparator #(
  parameter NUM_PATTERNS = 8
)(
  input wire [10:0] rx_id,
  input wire [10:0] match_patterns [0:NUM_PATTERNS-1],
  input wire [NUM_PATTERNS-1:0] pattern_enable,
  output wire [NUM_PATTERNS-1:0] pattern_match_results
);
  
  genvar i;
  
  // Generate comparison logic for each pattern
  generate
    for (i = 0; i < NUM_PATTERNS; i = i + 1) begin : pattern_compare
      assign pattern_match_results[i] = pattern_enable[i] && (rx_id == match_patterns[i]);
    end
  endgenerate
  
endmodule

///////////////////////////////////////////////////////////////////////////////
// Match Encoder Module
// Processes match results and generates output signals
///////////////////////////////////////////////////////////////////////////////

module match_encoder #(
  parameter NUM_PATTERNS = 8
)(
  input wire clk, rst_n,
  input wire id_valid,
  input wire [NUM_PATTERNS-1:0] pattern_match_results,
  output reg id_match,
  output reg [NUM_PATTERNS-1:0] pattern_matched,
  output reg [7:0] match_index
);

  integer j;

  // Priority encoder with synchronous reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end else if (id_valid) begin
      id_match <= 0;
      pattern_matched <= 0;
      
      // Process matches with priority encoding
      for (j = 0; j < NUM_PATTERNS; j = j + 1) begin
        if (pattern_match_results[j]) begin
          id_match <= 1;
          pattern_matched[j] <= 1;
          match_index <= j;
        end
      end
    end
  end
  
endmodule