//SystemVerilog
//-----------------------------------------------------------------------------
// Title: PWM Generator System
// Description: Top-level module for PWM generation with enhanced hierarchical structure
// Standard: IEEE 1364-2005 Verilog
//-----------------------------------------------------------------------------
module pwm_generator_system #(
  parameter COUNTER_SIZE = 8
)(
  input  wire                     clk,          // System clock
  input  wire                     rst,          // System reset
  input  wire [COUNTER_SIZE-1:0]  duty_cycle,   // Desired PWM duty cycle
  output wire                     pwm_out       // PWM output signal
);

  // Internal signals
  wire [COUNTER_SIZE-1:0] counter_value;
  wire compare_result;
  wire sync_rst;
  
  // Reset synchronizer instantiation
  reset_synchronizer reset_sync_inst (
    .clk          (clk),
    .async_rst    (rst),
    .sync_rst     (sync_rst)
  );
  
  // Counter module instantiation
  counter_module #(
    .COUNTER_WIDTH(COUNTER_SIZE)
  ) counter_inst (
    .clk          (clk),
    .rst          (sync_rst),
    .counter_out  (counter_value)
  );
  
  // Comparator logic instantiation
  comparator_logic #(
    .DATA_WIDTH   (COUNTER_SIZE)
  ) comparator_inst (
    .counter_value(counter_value),
    .threshold    (duty_cycle),
    .compare_out  (compare_result)
  );
  
  // Output register module instantiation
  output_register pwm_output_inst (
    .clk          (clk),
    .rst          (sync_rst),
    .data_in      (compare_result),
    .data_out     (pwm_out)
  );
  
endmodule

//-----------------------------------------------------------------------------
// Reset Synchronizer: Synchronizes asynchronous reset to clock domain
//-----------------------------------------------------------------------------
module reset_synchronizer (
  input  wire clk,        // System clock
  input  wire async_rst,  // Asynchronous reset input
  output reg  sync_rst    // Synchronized reset output
);

  // Two-stage synchronizer to prevent metastability
  reg rst_meta;
  
  always @(posedge clk or posedge async_rst) begin
    if (async_rst) begin
      rst_meta  <= 1'b1;
      sync_rst  <= 1'b1;
    end else begin
      rst_meta  <= 1'b0;
      sync_rst  <= rst_meta;
    end
  end
  
endmodule

//-----------------------------------------------------------------------------
// Counter Module: Generates a free-running counter
//-----------------------------------------------------------------------------
module counter_module #(
  parameter COUNTER_WIDTH = 8
)(
  input  wire                       clk,          // System clock
  input  wire                       rst,          // Synchronized reset
  output reg  [COUNTER_WIDTH-1:0]   counter_out   // Counter output value
);
  
  always @(posedge clk) begin
    if (rst) begin
      counter_out <= {COUNTER_WIDTH{1'b0}};
    end else begin
      counter_out <= counter_out + 1'b1;
    end
  end
  
endmodule

//-----------------------------------------------------------------------------
// Comparator Logic: Combinational comparison of counter against threshold
//-----------------------------------------------------------------------------
module comparator_logic #(
  parameter DATA_WIDTH = 8
)(
  input  wire [DATA_WIDTH-1:0] counter_value,  // Current counter value
  input  wire [DATA_WIDTH-1:0] threshold,      // Duty cycle threshold
  output wire                  compare_out     // Comparison result
);
  
  // Pure combinational logic for better timing
  assign compare_out = (counter_value < threshold);
  
endmodule

//-----------------------------------------------------------------------------
// Output Register: Registers the comparator output
//-----------------------------------------------------------------------------
module output_register (
  input  wire clk,       // System clock
  input  wire rst,       // Synchronized reset
  input  wire data_in,   // Input data from comparator
  output reg  data_out   // Registered output (PWM signal)
);
  
  always @(posedge clk) begin
    if (rst) begin
      data_out <= 1'b0;
    end else begin
      data_out <= data_in;
    end
  end
  
endmodule