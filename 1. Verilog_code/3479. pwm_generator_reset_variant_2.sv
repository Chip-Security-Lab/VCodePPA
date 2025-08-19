//SystemVerilog (IEEE 1364-2005)
// Top-level module - PWM Generator
module pwm_generator_reset #(
  parameter COUNTER_SIZE = 8
)(
  input  wire                       clk,       // System clock
  input  wire                       rst,       // Reset signal
  input  wire [COUNTER_SIZE-1:0]    duty_cycle,// Duty cycle control input
  output wire                       pwm_out    // PWM output signal
);

  // Internal signal declarations
  wire [COUNTER_SIZE-1:0] counter_value;
  
  // Register duty_cycle at input to improve timing
  reg [COUNTER_SIZE-1:0] duty_cycle_reg;
  
  always @(posedge clk) begin
    if (rst) begin
      duty_cycle_reg <= {COUNTER_SIZE{1'b0}};
    end else begin
      duty_cycle_reg <= duty_cycle;
    end
  end
  
  // PWM timing controller - handles counter operation
  pwm_timing_controller #(
    .WIDTH(COUNTER_SIZE)
  ) timing_ctrl_inst (
    .clk         (clk),
    .rst         (rst),
    .count_value (counter_value)
  );
  
  // PWM waveform generator - produces output based on comparison
  pwm_waveform_generator #(
    .WIDTH(COUNTER_SIZE)
  ) waveform_gen_inst (
    .clk          (clk),
    .rst          (rst),
    .counter_val  (counter_value),
    .duty_cycle   (duty_cycle_reg),
    .pwm_signal   (pwm_out)
  );

endmodule

// Timer submodule - implements an efficient free-running counter
module pwm_timing_controller #(
  parameter WIDTH = 8
)(
  input  wire               clk,
  input  wire               rst,
  output wire [WIDTH-1:0]   count_value
);
  
  reg [WIDTH-1:0] count_next;
  reg [WIDTH-1:0] count_reg;
  
  // Pre-compute next counter value (moved combinational logic before register)
  always @(*) begin
    count_next = count_reg + 1'b1;
  end
  
  // Register the counter value after computation
  always @(posedge clk) begin
    if (rst) begin
      count_reg <= {WIDTH{1'b0}};
    end else begin
      count_reg <= count_next;
    end
  end
  
  // Output assignment
  assign count_value = count_reg;

endmodule

// PWM waveform generator - produces the PWM signal based on comparison
module pwm_waveform_generator #(
  parameter WIDTH = 8
)(
  input  wire              clk,
  input  wire              rst,
  input  wire [WIDTH-1:0]  counter_val,
  input  wire [WIDTH-1:0]  duty_cycle,
  output reg               pwm_signal
);

  // Pre-compute comparison result (moved combinational logic before register)
  wire comparison_result;
  assign comparison_result = (counter_val < duty_cycle);
  
  // Register the comparison result
  always @(posedge clk) begin
    if (rst) begin
      pwm_signal <= 1'b0;
    end else begin
      pwm_signal <= comparison_result;
    end
  end

endmodule