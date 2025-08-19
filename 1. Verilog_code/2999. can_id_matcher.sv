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
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id_match <= 0;
      pattern_matched <= 0;
      match_index <= 0;
    end else if (id_valid) begin
      id_match <= 0;
      pattern_matched <= 0;
      
      for (i = 0; i < NUM_PATTERNS; i = i + 1) begin
        if (pattern_enable[i] && (rx_id == match_patterns[i])) begin
          id_match <= 1;
          pattern_matched[i] <= 1;
          match_index <= i;
        end
      end
    end
  end
endmodule