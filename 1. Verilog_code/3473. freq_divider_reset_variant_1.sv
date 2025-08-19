//SystemVerilog
module freq_divider_reset #(parameter DIVISOR = 10)(
  input clk_in, reset,
  output reg clk_out
);
  reg [$clog2(DIVISOR)-1:0] counter;
  wire [$clog2(DIVISOR)-1:0] counter_next;
  wire counter_wrapped;
  
  // 使用条件求和减法算法实现减法功能
  // 当counter == DIVISOR-1时，需要清零并翻转时钟
  assign {counter_wrapped, counter_next} = (counter == 0) ? 
                                          {1'b0, 1'b1} : 
                                          (counter == DIVISOR-2) ? 
                                          {1'b1, {$clog2(DIVISOR){1'b0}}} : 
                                          {1'b0, counter + 1'b1};
  
  always @(posedge clk_in) begin
    if (reset) begin
      counter <= 0;
      clk_out <= 0;
    end else begin
      counter <= counter_next;
      if (counter_wrapped)
        clk_out <= ~clk_out;
    end
  end
endmodule