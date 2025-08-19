module programmable_timeout_reset #(parameter CLK_FREQ = 100000)(
  input clk, rst_n, enable,
  input [31:0] timeout_ms,
  input timeout_trigger, timeout_clear,
  output reg reset_out,
  output reg timeout_active
);
  reg [31:0] counter = 32'h00000000;
  wire [31:0] timeout_cycles = timeout_ms * (CLK_FREQ / 1000);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 32'h00000000;
      timeout_active <= 1'b0;
      reset_out <= 1'b0;
    end else if (!enable) begin
      counter <= 32'h00000000;
      timeout_active <= 1'b0;
      reset_out <= 1'b0;
    end else if (timeout_clear) begin
      counter <= 32'h00000000;
      timeout_active <= 1'b0;
      reset_out <= 1'b0;
    end else if (timeout_trigger && !timeout_active) begin
      counter <= 32'h00000001;
      timeout_active <= 1'b1;
      reset_out <= 1'b0;
    end else if (timeout_active) begin
      if (counter < timeout_cycles) begin
        counter <= counter + 32'h00000001;
        reset_out <= 1'b0;
      end else begin
        reset_out <= 1'b1;
      end
    end
  end
endmodule