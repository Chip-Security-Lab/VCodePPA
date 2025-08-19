//SystemVerilog
module pattern_detector_reset #(parameter PATTERN = 8'b10101010)(
  input wire clk,
  input wire rst,
  input wire data_in,
  input wire valid_in,
  output wire pattern_detected,
  output wire valid_out
);
  // Stage 1: Input data shift register
  reg [7:0] shift_reg_stage1;
  reg valid_stage1;
  
  // Stage 2: Pattern comparison
  reg pattern_match_stage2;
  reg valid_stage2;
  
  // Stage 1: Shift register
  always @(posedge clk) begin
    if (rst) begin
      shift_reg_stage1 <= 8'b0;
      valid_stage1 <= 1'b0;
    end else begin
      if (valid_in) begin
        shift_reg_stage1 <= {shift_reg_stage1[6:0], data_in};
      end
      valid_stage1 <= valid_in;
    end
  end
  
  // Stage 2: Pattern comparison
  always @(posedge clk) begin
    if (rst) begin
      pattern_match_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      if (valid_stage1) begin
        pattern_match_stage2 <= (shift_reg_stage1 == PATTERN);
      end
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Output assignment
  assign pattern_detected = pattern_match_stage2;
  assign valid_out = valid_stage2;
endmodule