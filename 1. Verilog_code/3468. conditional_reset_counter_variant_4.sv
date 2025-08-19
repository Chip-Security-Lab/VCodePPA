//SystemVerilog
module conditional_reset_counter #(parameter WIDTH = 12)(
  input clk, reset_n, condition, enable,
  output reg [WIDTH-1:0] value
);
  // Register the input signals
  reg reset_n_reg, condition_reg, enable_reg;
  
  // Separate control signals for better timing balance
  reg increment_value, hold_value, reset_value;
  
  // Register inputs on clock edge
  always @(posedge clk) begin
    reset_n_reg <= reset_n;
    condition_reg <= condition;
    enable_reg <= enable;
  end
  
  // Simplified and balanced control logic with fewer logic levels
  always @(*) begin
    // Default values to avoid latches
    increment_value = 1'b0;
    hold_value = 1'b0;
    reset_value = 1'b0;
    
    // Reset condition (highest priority)
    if (!reset_n_reg || (reset_n_reg && condition_reg && enable_reg)) begin
      reset_value = 1'b1;
    end
    // Increment condition
    else if (reset_n_reg && !condition_reg && enable_reg) begin
      increment_value = 1'b1;
    end
    // Hold condition
    else begin
      hold_value = 1'b1;
    end
  end
  
  // Value update logic with direct reset for timing
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      value <= {WIDTH{1'b0}};
    end
    else begin
      if (reset_value) begin
        value <= {WIDTH{1'b0}};
      end
      else if (increment_value) begin
        value <= value + 1'b1;
      end
      // Hold value is implicit when neither reset nor increment
    end
  end
endmodule