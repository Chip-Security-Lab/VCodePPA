module threshold_reset_detector #(parameter WIDTH = 8)(
  input clk, enable,
  input [WIDTH-1:0] voltage_level, threshold,
  output reg reset_out
);
  reg [2:0] consecutive_under = 0;
  
  always @(posedge clk) begin
    if (!enable) begin
      reset_out <= 1'b0;
      consecutive_under <= 0;
    end else begin
      if (voltage_level < threshold)
        consecutive_under <= consecutive_under < 5 ? consecutive_under + 1 : 5;
      else
        consecutive_under <= 0;
      
      reset_out <= (consecutive_under >= 3);
    end
  end
endmodule