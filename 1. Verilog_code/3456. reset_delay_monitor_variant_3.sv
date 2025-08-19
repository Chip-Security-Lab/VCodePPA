//SystemVerilog
module reset_delay_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stuck_error
);
  // Pipeline stage 1 registers
  reg reset_n_stage1;
  reg [7:0] counter_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 registers
  reg reset_n_stage2;
  reg [15:0] counter_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers
  reg reset_stuck_error_stage3;
  
  // Counter full detection signals
  wire counter_stage1_full;
  wire counter_full;
  
  // Optimize comparison logic with direct assignment
  assign counter_stage1_full = &counter_stage1;
  assign counter_full = counter_stage1_full && &counter_stage2;
  
  // Pipeline stage 1: Input registration and lower counter bits
  always @(posedge clk) begin
    // Register inputs
    reset_n_stage1 <= reset_n;
    valid_stage1 <= 1'b1; // Always valid after first cycle
    
    // First part of counter logic - optimized reset condition
    counter_stage1 <= reset_n_stage1 ? 8'h00 : (counter_stage1 + 1'b1);
  end
  
  // Pipeline stage 2: Upper counter bits and counter overflow detection
  always @(posedge clk) begin
    // Forward control signals
    reset_n_stage2 <= reset_n_stage1;
    valid_stage2 <= valid_stage1;
    
    // Second part of counter logic - optimized conditional structure
    if (valid_stage1) begin
      if (!reset_n_stage1 && counter_stage1_full)
        counter_stage2 <= counter_stage2 + 1'b1;
      else if (reset_n_stage1)
        counter_stage2 <= 16'h0000;
    end
  end
  
  // Pipeline stage 3: Error detection and output
  always @(posedge clk) begin
    if (valid_stage2) begin
      // Simplified error detection logic
      reset_stuck_error_stage3 <= counter_full || 
                               (reset_stuck_error_stage3 && !reset_n_stage2);
    end
    
    // Final output assignment
    reset_stuck_error <= reset_stuck_error_stage3;
  end
endmodule