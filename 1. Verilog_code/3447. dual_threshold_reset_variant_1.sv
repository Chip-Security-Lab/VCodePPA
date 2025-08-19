//SystemVerilog
module dual_threshold_reset (
  input wire clk,
  input wire [7:0] level,
  input wire [7:0] upper_threshold,
  input wire [7:0] lower_threshold,
  input wire input_valid,  // Valid signal from upstream
  output reg input_ready,  // Ready signal to upstream
  output reg reset_out,
  output reg output_valid, // Valid signal to downstream
  input wire output_ready  // Ready signal from downstream
);
  
  reg [7:0] level_reg;
  reg [7:0] upper_threshold_reg;
  reg [7:0] lower_threshold_reg;
  reg processing;
  
  // Pre-computed comparison results (retimed back)
  reg level_gt_upper;
  reg level_lt_lower;
  
  // Input handshaking and data capture with pre-computation
  always @(posedge clk) begin
    if (!processing && input_valid && input_ready) begin
      level_reg <= level;
      upper_threshold_reg <= upper_threshold;
      lower_threshold_reg <= lower_threshold;
      
      // Pre-compute comparisons and move them before the main processing logic
      level_gt_upper <= level > upper_threshold;
      level_lt_lower <= level < lower_threshold;
      
      processing <= 1'b1;
      input_ready <= 1'b0; // Not ready for new input while processing
    end else if (processing && output_valid && output_ready) begin
      processing <= 1'b0;
      input_ready <= 1'b1; // Ready for new input after current output is accepted
    end else if (!processing && !input_ready) begin
      input_ready <= 1'b1; // Default state is ready for input
    end
  end
  
  // Core processing logic with retimed comparison logic
  always @(posedge clk) begin
    if (processing && !output_valid) begin
      // Use pre-computed comparison results instead of doing comparison in this stage
      if (!reset_out && level_gt_upper)
        reset_out <= 1'b1;
      else if (reset_out && level_lt_lower)
        reset_out <= 1'b0;
      output_valid <= 1'b1;
    end else if (output_valid && output_ready) begin
      output_valid <= 1'b0; // Clear valid after handshake completes
    end
  end
  
  // Initialize registers
  initial begin
    reset_out = 1'b0;
    input_ready = 1'b1;
    output_valid = 1'b0;
    processing = 1'b0;
    level_gt_upper = 1'b0;
    level_lt_lower = 1'b0;
  end
endmodule