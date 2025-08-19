//SystemVerilog
module selective_bit_reset(
  input clk, rst_n,
  input reset_bit0, reset_bit1, reset_bit2,
  input [2:0] data_in,
  output reg [2:0] data_out
);

  // 使用单独的变量储存下一状态
  reg [2:0] next_data;

  always @(*) begin
    // 默认保持当前值
    next_data = data_out;
    
    // 扁平化的位控制逻辑，使用逻辑与组合条件
    if (reset_bit0)
      next_data[0] = 1'b0;
    else 
      next_data[0] = data_in[0];
      
    if (reset_bit1)
      next_data[1] = 1'b0;
    else
      next_data[1] = data_in[1];
      
    if (reset_bit2)
      next_data[2] = 1'b0;
    else
      next_data[2] = data_in[2];
  end

  // 寄存器更新逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      data_out <= 3'b000;
    else
      data_out <= next_data;
  end

endmodule