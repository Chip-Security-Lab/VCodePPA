//SystemVerilog
module one_hot_encoder_reset(
  input clk, rst,
  input [2:0] binary_in,
  output reg [7:0] one_hot_out
);
  
  wire [7:0] one_hot_logic;
  
  // 组合逻辑部分，直接计算one-hot编码
  assign one_hot_logic = (8'h01 << binary_in);
  
  // 移动寄存器到组合逻辑之后，减少输入到第一级寄存器的延迟
  always @(posedge clk)
    one_hot_out <= rst ? 8'h00 : one_hot_logic;
    
endmodule