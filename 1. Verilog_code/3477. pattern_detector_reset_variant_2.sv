//SystemVerilog
module pattern_detector_reset #(parameter PATTERN = 8'b10101010)(
  input clk, rst, data_in,
  output reg pattern_detected
);
  reg [6:0] shift_reg;
  wire [7:0] full_pattern;
  wire pattern_match;
  
  assign full_pattern = {shift_reg, data_in};
  assign pattern_match = (full_pattern == PATTERN);
  
  always @(posedge clk) begin
    shift_reg <= rst ? 7'b0 : {shift_reg[5:0], data_in};
    pattern_detected <= rst ? 1'b0 : pattern_match;
  end
endmodule