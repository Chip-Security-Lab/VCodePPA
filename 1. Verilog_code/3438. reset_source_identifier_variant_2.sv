//SystemVerilog
module reset_source_identifier (
  input wire clk,
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output reg [3:0] reset_source
);
  
  // Using one-hot encoding for reset signals to balance paths
  reg pwr_reset_reg, wdt_reset_reg, sw_reset_reg, sys_reset_reg;
  reg [3:0] reset_priority;
  
  // First stage - register all reset inputs to reduce path delay
  always @(posedge clk) begin
    pwr_reset_reg <= pwr_reset;
    wdt_reset_reg <= wdt_reset;
    sw_reset_reg <= sw_reset;
    sys_reset_reg <= sys_reset;
  end
  
  // Second stage - priority encoding with balanced paths
  always @(*) begin
    // Default - no reset active
    reset_priority = 4'b0000;
    
    // Prioritized reset logic with balanced paths
    // Each path has 1-2 logic levels maximum
    if (pwr_reset_reg)
      reset_priority = 4'b0001;
    else if (wdt_reset_reg)
      reset_priority = 4'b0010;
    else if (sw_reset_reg)
      reset_priority = 4'b0100;
    else if (sys_reset_reg)
      reset_priority = 4'b1000;
  end
  
  // Final stage - translate priority to source code
  always @(posedge clk) begin
    case (reset_priority)
      4'b0001: reset_source <= 4'h1; // pwr_reset
      4'b0010: reset_source <= 4'h2; // wdt_reset
      4'b0100: reset_source <= 4'h3; // sw_reset
      4'b1000: reset_source <= 4'h4; // sys_reset
      default: reset_source <= 4'h0; // no reset or undefined state
    endcase
  end
  
endmodule