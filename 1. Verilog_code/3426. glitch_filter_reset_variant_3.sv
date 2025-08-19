//SystemVerilog
module glitch_filter_reset #(
  parameter GLITCH_CYCLES = 3
) (
  input wire clk,
  input wire noisy_rst,
  output reg clean_rst
);

  // State definitions
  localparam IDLE_LOW = 2'b00;  // Stable low state
  localparam RISING   = 2'b01;  // Potential rising edge
  localparam IDLE_HIGH = 2'b10; // Stable high state
  localparam FALLING  = 2'b11;  // Potential falling edge

  reg [1:0] state, next_state;
  reg [$clog2(GLITCH_CYCLES)-1:0] counter, next_counter;
  reg next_clean_rst;
  
  wire transition_complete;
  wire input_matches_output;
  wire input_differs_from_output;
  
  // Detect when transition counter has reached threshold
  assign transition_complete = (counter == GLITCH_CYCLES-1);
  
  // Detect when input matches current output state
  assign input_matches_output = (noisy_rst == clean_rst);
  
  // Detect when input differs from current output state
  assign input_differs_from_output = (noisy_rst != clean_rst);
  
  // State and outputs sequential logic
  always @(posedge clk) begin
    state <= next_state;
    counter <= next_counter;
    clean_rst <= next_clean_rst;
  end
  
  // Next state combinational logic
  always @(*) begin
    // Default: maintain current state
    next_state = state;
    
    if (state == IDLE_LOW) begin
      if (noisy_rst) begin 
        next_state = RISING;
      end
    end
    else if (state == RISING) begin
      if (!noisy_rst) begin
        next_state = IDLE_LOW;
      end
      else if (transition_complete) begin
        next_state = IDLE_HIGH;
      end
    end
    else if (state == IDLE_HIGH) begin
      if (!noisy_rst) begin
        next_state = FALLING;
      end
    end
    else if (state == FALLING) begin
      if (noisy_rst) begin
        next_state = IDLE_HIGH;
      end
      else if (transition_complete) begin
        next_state = IDLE_LOW;
      end
    end
  end
  
  // Counter management logic
  always @(*) begin
    // Default: maintain current counter value
    next_counter = counter;
    
    if (state == IDLE_LOW) begin
      if (noisy_rst) begin
        next_counter = 0;
      end
    end
    else if (state == RISING) begin
      if (!noisy_rst) begin
        // Reset counter when returning to idle
      end
      else if (transition_complete) begin
        // Counter reaches maximum, reset not needed
      end
      else begin
        next_counter = counter + 1;
      end
    end
    else if (state == IDLE_HIGH) begin
      if (!noisy_rst) begin
        next_counter = 0;
      end
    end
    else if (state == FALLING) begin
      if (noisy_rst) begin
        // Reset counter when returning to idle
      end
      else if (transition_complete) begin
        // Counter reaches maximum, reset not needed
      end
      else begin
        next_counter = counter + 1;
      end
    end
  end
  
  // Output logic
  always @(*) begin
    // Default: maintain current output
    next_clean_rst = clean_rst;
    
    if (state == IDLE_LOW) begin
      // No change to output
    end
    else if (state == RISING) begin
      if (transition_complete) begin
        next_clean_rst = 1'b1;
      end
    end
    else if (state == IDLE_HIGH) begin
      // No change to output
    end
    else if (state == FALLING) begin
      if (transition_complete) begin
        next_clean_rst = 1'b0;
      end
    end
  end

endmodule