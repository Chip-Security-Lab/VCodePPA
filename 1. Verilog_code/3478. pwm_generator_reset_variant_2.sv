//SystemVerilog
module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input clk, rst,
  input [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  reg [COUNTER_SIZE-1:0] counter;
  reg [COUNTER_SIZE-1:0] duty_cycle_reg;
  wire pwm_comb;
  
  // Buffered reset signals to reduce fanout
  reg rst_buf1, rst_buf2, rst_buf3;
  
  // Reset signal buffering
  always @(posedge clk) begin
    rst_buf1 <= rst;
    rst_buf2 <= rst_buf1;
    rst_buf3 <= rst_buf1;
  end
  
  // Duty cycle registration with dedicated reset buffer
  always @(posedge clk) begin
    if (rst_buf1) begin
      duty_cycle_reg <= {COUNTER_SIZE{1'b0}};
    end else begin
      duty_cycle_reg <= duty_cycle;
    end
  end
  
  // Counter logic with dedicated reset buffer
  always @(posedge clk) begin
    if (rst_buf2) begin
      counter <= {COUNTER_SIZE{1'b0}};
    end else begin
      counter <= counter + 1'b1;
    end
  end
  
  // Split counter into two parts to reduce comparator delay
  wire [COUNTER_SIZE/2-1:0] counter_low = counter[COUNTER_SIZE/2-1:0];
  wire [COUNTER_SIZE/2-1:0] counter_high = counter[COUNTER_SIZE-1:COUNTER_SIZE/2];
  wire [COUNTER_SIZE/2-1:0] duty_low = duty_cycle_reg[COUNTER_SIZE/2-1:0];
  wire [COUNTER_SIZE/2-1:0] duty_high = duty_cycle_reg[COUNTER_SIZE-1:COUNTER_SIZE/2];
  
  // Optimized comparison logic with balanced paths
  wire comp_low = (counter_low < duty_low);
  wire comp_high = (counter_high < duty_high);
  wire comp_equal_high = (counter_high == duty_high);
  assign pwm_comb = (counter_high < duty_high) || 
                   ((counter_high == duty_high) && (counter_low < duty_low));
  
  // PWM output with dedicated reset buffer
  always @(posedge clk) begin
    if (rst_buf3) begin
      pwm_out <= 1'b0;
    end else begin
      pwm_out <= pwm_comb;
    end
  end
endmodule