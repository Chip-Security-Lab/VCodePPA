//SystemVerilog
module RD8 #(parameter SIZE=4)(
  input wire clk,
  input wire rst,
  output reg [SIZE-1:0] ring
);

  // 定义中间流水线寄存器，用于切割关键路径
  reg [SIZE-1:0] next_ring_stage1;
  reg [SIZE-1:0] next_ring;
  reg msb_detected;  // 检测MSB的流水线寄存器
  
  // 第一级组合逻辑 - 检测MSB并开始计算
  always @(*) begin
    msb_detected = ring[SIZE-1];
    
    // 初始化中间结果
    next_ring_stage1 = {SIZE{1'b0}};
    
    // 第一级计算 - 检测中间位的1并准备移位
    if (!msb_detected) begin
      integer i;
      for (i = 0; i < SIZE-1; i = i + 1) begin
        if (ring[i]) 
          next_ring_stage1[i+1] = 1'b1;
      end
    end
  end
  
  // 第二级组合逻辑 - 基于第一级的结果完成计算
  always @(*) begin
    if (msb_detected)
      next_ring = {{(SIZE-1){1'b0}}, 1'b1}; // 如果MSB为1，则循环到初始状态
    else
      next_ring = next_ring_stage1;
  end
  
  // 寄存器更新逻辑
  always @(posedge clk) begin
    if (rst) 
      ring <= {{(SIZE-1){1'b0}}, 1'b1}; // 复位状态为最低位为1
    else 
      ring <= next_ring;
  end

endmodule