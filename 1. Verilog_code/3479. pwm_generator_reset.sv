module pwm_generator_reset #(parameter COUNTER_SIZE = 8)(
  input clk, rst,
  input [COUNTER_SIZE-1:0] duty_cycle,
  output reg pwm_out
);
  reg [COUNTER_SIZE-1:0] counter;
  
  always @(posedge clk) begin
    if (rst) begin
      counter <= {COUNTER_SIZE{1'b0}};
      pwm_out <= 1'b0;
    end else begin
      counter <= counter + 1'b1;
      pwm_out <= (counter < duty_cycle);
    end
  end
endmodule