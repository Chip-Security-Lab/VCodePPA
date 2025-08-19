//SystemVerilog
module reset_stretcher #(
  parameter STRETCH_CYCLES = 16
) (
  input wire clk,
  input wire reset_in,
  output reg reset_out
);
  reg [$clog2(STRETCH_CYCLES):0] counter;
  reg [$clog2(STRETCH_CYCLES):0] counter_next;
  wire subtract_enable;
  
  assign subtract_enable = (counter > 0) & ~reset_in;
  
  // 使用if-else结构替代条件运算符
  always @(*) begin
    if (reset_in) begin
      counter_next = STRETCH_CYCLES;
    end else begin
      if (subtract_enable) begin
        counter_next = counter - 1'b1;
      end else begin
        counter_next = counter;
      end
    end
  end
  
  always @(posedge clk) begin
    counter <= counter_next;
    
    // 使用if-else结构替代条件运算符
    if ((counter > 0) || reset_in) begin
      reset_out <= 1'b1;
    end else begin
      reset_out <= 1'b0;
    end
  end
endmodule