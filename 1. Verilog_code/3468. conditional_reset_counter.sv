module conditional_reset_counter #(parameter WIDTH = 12)(
  input clk, reset_n, condition, enable,
  output reg [WIDTH-1:0] value
);
  always @(posedge clk) begin
    if (!reset_n)
      value <= {WIDTH{1'b0}};
    else if (condition && enable)
      value <= {WIDTH{1'b0}};  // Conditional reset
    else if (enable)
      value <= value + 1'b1;
  end
endmodule