//SystemVerilog
module reset_generator_debounce #(parameter DEBOUNCE_LEN = 4)(
  input wire clk, button_in,
  output reg reset_out
);
  // Input stage pipeline register
  reg button_in_stage1;
  
  // Debounce shift register with multiple stages - optimized implementation
  reg [DEBOUNCE_LEN-1:0] debounce_reg;
  
  // Optimized signal detection
  wire all_ones;
  wire all_zeros;
  reg reset_determination;
  
  // Input stage - capture button input
  always @(posedge clk) begin
    button_in_stage1 <= button_in;
  end
  
  // Combined stage - Update debounce register in single pipeline
  always @(posedge clk) begin
    debounce_reg <= {debounce_reg[DEBOUNCE_LEN-2:0], button_in_stage1};
  end
  
  // Optimized condition detection using continuous assignment
  assign all_ones = &debounce_reg;
  assign all_zeros = ~|debounce_reg;
  
  // Reset determination logic with priority encoding
  always @(posedge clk) begin
    if (all_ones)
      reset_determination <= 1'b1;
    else if (all_zeros)
      reset_determination <= 1'b0;
  end
  
  // Final output stage
  always @(posedge clk) begin
    reset_out <= reset_determination;
  end
endmodule