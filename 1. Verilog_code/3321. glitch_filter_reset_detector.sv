module glitch_filter_reset_detector(
  input clk, rst_n,
  input raw_reset,
  output reg filtered_reset
);
  reg [7:0] shift_reg;
  reg reset_detected;
  
  // 用函数替代$countones系统函数
  function [3:0] count_ones;
    input [7:0] data;
    integer i;
    begin
      count_ones = 0;
      for (i = 0; i < 8; i = i + 1)
        if (data[i]) count_ones = count_ones + 1;
    end
  endfunction
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      shift_reg <= 8'h00;
      reset_detected <= 1'b0;
      filtered_reset <= 1'b0;
    end else begin
      shift_reg <= {shift_reg[6:0], raw_reset};
      
      // 使用自定义函数检测多数样本是否为高
      reset_detected <= (count_ones(shift_reg) >= 5);
      
      // Hysteresis: need 2 consecutive detections to trigger, 
      // and 2 consecutive non-detections to clear
      if (reset_detected && filtered_reset)
        filtered_reset <= 1'b1;
      else if (reset_detected && !filtered_reset)
        filtered_reset <= 1'b1;
      else if (!reset_detected && filtered_reset)
        filtered_reset <= shift_reg[7:6] != 2'b00;
      else
        filtered_reset <= 1'b0;
    end
  end
endmodule