module reset_pattern_detector (
  input wire clk,
  input wire reset_sig,
  output reg pattern_detected
);
  reg [7:0] shift_reg;
  localparam PATTERN = 8'b10101010;
  
  always @(posedge clk) begin
    shift_reg <= {shift_reg[6:0], reset_sig};
    pattern_detected <= (shift_reg == PATTERN);
  end
endmodule