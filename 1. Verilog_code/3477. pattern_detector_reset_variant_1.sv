//SystemVerilog
module pattern_detector_reset #(parameter PATTERN = 8'b10101010)(
  input clk, rst, data_in,
  output reg pattern_detected
);
  reg [6:0] data_shift_reg;
  wire [7:0] complete_pattern;
  wire pattern_match;
  
  // Construct the complete pattern for comparison
  assign complete_pattern = {data_shift_reg, data_in};
  
  // Move pattern detection logic to combinational path
  assign pattern_match = (complete_pattern == PATTERN);
  
  always @(posedge clk) begin
    if (rst) begin
      data_shift_reg <= 7'b0;
      pattern_detected <= 1'b0;
    end else begin
      // Store only 7 bits instead of 8
      data_shift_reg <= {data_shift_reg[5:0], data_in};
      // Register the pattern detection result
      pattern_detected <= pattern_match;
    end
  end
endmodule