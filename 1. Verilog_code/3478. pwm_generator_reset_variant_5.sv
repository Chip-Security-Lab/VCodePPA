//SystemVerilog
//========================================================================
// Top-level PWM Generator Module
//========================================================================
module pwm_generator_reset #(
  parameter COUNTER_SIZE = 8
)(
  input  wire                    clk,
  input  wire                    rst,
  input  wire [COUNTER_SIZE-1:0] duty_cycle,
  output wire                    pwm_out
);

  // Interface signals between submodules
  wire [COUNTER_SIZE-1:0] duty_cycle_reg;
  wire [COUNTER_SIZE-1:0] counter_value;
  wire                    pwm_comb;

  // Input Register Submodule
  duty_cycle_register #(
    .WIDTH(COUNTER_SIZE)
  ) duty_reg_inst (
    .clk          (clk),
    .rst          (rst),
    .duty_cycle_in(duty_cycle),
    .duty_cycle_out(duty_cycle_reg)
  );

  // Counter Submodule
  counter_module #(
    .COUNTER_WIDTH(COUNTER_SIZE)
  ) counter_inst (
    .clk          (clk),
    .rst          (rst),
    .counter_value(counter_value)
  );

  // Comparator Submodule
  pwm_comparator #(
    .WIDTH(COUNTER_SIZE)
  ) comparator_inst (
    .counter     (counter_value),
    .duty_cycle  (duty_cycle_reg),
    .pwm_comb    (pwm_comb)
  );

  // Output Register Submodule
  output_register output_reg_inst (
    .clk      (clk),
    .rst      (rst),
    .pwm_in   (pwm_comb),
    .pwm_out  (pwm_out)
  );

endmodule

//========================================================================
// Duty Cycle Register Submodule
//========================================================================
module duty_cycle_register #(
  parameter WIDTH = 8
)(
  input  wire             clk,
  input  wire             rst,
  input  wire [WIDTH-1:0] duty_cycle_in,
  output reg  [WIDTH-1:0] duty_cycle_out
);

  always @(posedge clk) begin
    if (rst) begin
      duty_cycle_out <= {WIDTH{1'b0}};
    end else begin
      duty_cycle_out <= duty_cycle_in;
    end
  end

endmodule

//========================================================================
// Counter Submodule
//========================================================================
module counter_module #(
  parameter COUNTER_WIDTH = 8
)(
  input  wire                   clk,
  input  wire                   rst,
  output reg [COUNTER_WIDTH-1:0] counter_value
);

  always @(posedge clk) begin
    if (rst) begin
      counter_value <= {COUNTER_WIDTH{1'b0}};
    end else begin
      counter_value <= counter_value + 1'b1;
    end
  end

endmodule

//========================================================================
// PWM Comparator Submodule
//========================================================================
module pwm_comparator #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] counter,
  input  wire [WIDTH-1:0] duty_cycle,
  output wire             pwm_comb
);

  // Comparison logic
  assign pwm_comb = (counter < duty_cycle);

endmodule

//========================================================================
// Output Register Submodule
//========================================================================
module output_register (
  input  wire clk,
  input  wire rst,
  input  wire pwm_in,
  output reg  pwm_out
);

  always @(posedge clk) begin
    if (rst) begin
      pwm_out <= 1'b0;
    end else begin
      pwm_out <= pwm_in;
    end
  end

endmodule