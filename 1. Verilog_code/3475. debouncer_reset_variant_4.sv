//SystemVerilog
module debouncer_reset #(parameter DELAY = 16)(
  input clk, rst, button_in,
  output reg button_out
);
  reg [DELAY-2:0] shift_reg;
  reg button_in_reg;
  reg all_ones_reg, all_zeros_reg;
  
  // Pre-compute the detection logic outside the main clock process
  // This breaks up the long combinational path
  always @(*) begin
    all_ones_reg = &{shift_reg, button_in_reg};
    all_zeros_reg = ~|{shift_reg, button_in_reg};
  end
  
  always @(posedge clk) begin
    if (rst) begin
      button_in_reg <= 1'b0;
      shift_reg <= {(DELAY-1){1'b0}};
      button_out <= 1'b0;
    end else begin
      // Register input to reduce input path delay
      button_in_reg <= button_in;
      
      // Shift operation
      shift_reg <= {shift_reg[DELAY-3:0], button_in_reg};
      
      // Use pre-computed detection signals for button_out
      if (all_ones_reg)
        button_out <= 1'b1;
      else if (all_zeros_reg)
        button_out <= 1'b0;
    end
  end
endmodule