module pattern_detector_reset #(parameter PATTERN = 8'b10101010)(
  input clk, rst, data_in,
  output reg pattern_detected
);
  reg [7:0] shift_reg;
  
  always @(posedge clk) begin
    if (rst) begin
      shift_reg <= 8'b0;
      pattern_detected <= 1'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], data_in};
      pattern_detected <= (shift_reg == PATTERN);
    end
  end
endmodule