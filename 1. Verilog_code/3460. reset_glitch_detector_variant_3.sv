//SystemVerilog
///////////////////////////////////////////////////////////
// File: reset_glitch_detector_top.v
// Description: Top module for reset glitch detection system
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////

module reset_glitch_detector_top (
  input  wire clk,        // System clock
  input  wire reset_n,    // Active low reset signal
  output wire glitch_detected  // Glitch detection output
);

  // Internal signals for connecting submodules
  wire reset_transition_occurred;

  // Instantiate signal monitoring submodule
  reset_signal_monitor u_reset_signal_monitor (
    .clk                (clk),
    .reset_n            (reset_n),
    .transition_detected(reset_transition_occurred)
  );

  // Instantiate glitch flag management submodule
  reset_glitch_flag_controller u_reset_glitch_flag_controller (
    .clk                (clk),
    .transition_detected(reset_transition_occurred),
    .glitch_detected    (glitch_detected)
  );

endmodule

///////////////////////////////////////////////////////////
// File: reset_signal_monitor.v
// Description: Monitors reset signal for transitions
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////

module reset_signal_monitor (
  input  wire clk,                // System clock
  input  wire reset_n,            // Active low reset signal
  output reg  transition_detected // Flag for transition detection
);
  
  // Internal registers to improve path balancing
  reg reset_n_ff1;   // First stage FF for reset_n
  reg reset_n_ff2;   // Second stage FF for reset_n
  
  // Two-stage synchronization and edge detection with balanced paths
  always @(posedge clk) begin
    // First stage synchronization
    reset_n_ff1 <= reset_n;
    // Second stage synchronization
    reset_n_ff2 <= reset_n_ff1;
    // Detect transition with balanced logic
    transition_detected <= reset_n_ff1 ^ reset_n_ff2;
  end
  
endmodule

///////////////////////////////////////////////////////////
// File: reset_glitch_flag_controller.v
// Description: Manages the glitch detection flag
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////

module reset_glitch_flag_controller (
  input  wire clk,                 // System clock
  input  wire transition_detected, // Signal transition indicator
  output reg  glitch_detected      // Final glitch detection output
);
  
  // Reset signal for glitch flag
  reg clear_glitch_flag;
  
  // Initialize internal register
  initial begin
    glitch_detected = 1'b0;
    clear_glitch_flag = 1'b0;
  end
  
  // Glitch flag management with optimized path balancing
  always @(posedge clk) begin
    // Set flag immediately on transition - optimized critical path
    glitch_detected <= transition_detected | (glitch_detected & ~clear_glitch_flag);
    
    // Clear flag control logic - separated for path balancing
    clear_glitch_flag <= glitch_detected & transition_detected;
  end
  
endmodule