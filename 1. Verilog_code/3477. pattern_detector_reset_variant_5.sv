//SystemVerilog
module pattern_detector_reset #(parameter PATTERN = 8'b10101010)(
  input clk, rst, data_in,
  output reg pattern_detected
);
  reg [6:0] shift_reg;
  wire [7:0] current_pattern;
  
  assign current_pattern = {shift_reg, data_in};
  
  always @(posedge clk) begin
    if (rst) begin
      shift_reg <= 7'b0;
      pattern_detected <= 1'b0;
    end else begin
      shift_reg <= {shift_reg[5:0], data_in};
      pattern_detected <= (current_pattern == PATTERN);
    end
  end
endmodule