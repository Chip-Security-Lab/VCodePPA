module freq_divider_reset #(parameter DIVISOR = 10)(
  input clk_in, reset,
  output reg clk_out
);
  reg [$clog2(DIVISOR)-1:0] counter;
  
  always @(posedge clk_in) begin
    if (reset) begin
      counter <= 0;
      clk_out <= 0;
    end else begin
      if (counter == DIVISOR - 1) begin
        counter <= 0;
        clk_out <= ~clk_out;
      end else
        counter <= counter + 1;
    end
  end
endmodule
