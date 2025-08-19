//SystemVerilog
module reset_pattern_detector (
  input wire clk,
  input wire reset_sig,
  input wire req,         // Request signal (was valid)
  output reg ack,         // Acknowledge signal (was ready)
  output reg pattern_detected
);
  // Pipeline registers
  reg [6:0] shift_reg;
  reg [3:0] pattern_first_half;
  reg [3:0] pattern_second_half;
  reg partial_match_stage1;
  
  // State for handshake control
  reg processing;
  
  // Localparam for pattern definition
  localparam PATTERN = 8'b10101010;
  localparam PATTERN_FIRST = 4'b1010;
  localparam PATTERN_SECOND = 4'b1010;
  
  // Handshake logic
  always @(posedge clk) begin
    if (req && !processing) begin
      processing <= 1'b1;
      ack <= 1'b0;
    end
    else if (processing) begin
      ack <= 1'b1;
      if (ack)
        processing <= 1'b0;
    end
    else begin
      ack <= 1'b0;
    end
  end
  
  // First pipeline stage - input registration and split pattern matching
  always @(posedge clk) begin
    if (req && !processing) begin
      // Shift register for input capture
      shift_reg <= {shift_reg[5:0], reset_sig};
      
      // Store first and second half of the pattern for comparison
      pattern_first_half <= {shift_reg[2:0], reset_sig};
      pattern_second_half <= shift_reg[6:3];
      
      // First stage comparison result
      partial_match_stage1 <= (pattern_first_half == PATTERN_FIRST);
    end
  end
  
  // Second pipeline stage - final pattern detection
  always @(posedge clk) begin
    if (processing && !ack)
      pattern_detected <= partial_match_stage1 && (pattern_second_half == PATTERN_SECOND);
  end
endmodule