//SystemVerilog
module priority_parity_gen(
  input [15:0] data,
  input [3:0] priority_level,
  output parity_result
);
  // 根据优先级屏蔽的数据
  reg [15:0] masked_data;
  // 用于存储中间结果
  wire [15:0] priority_mask;
  
  // 生成优先级掩码 - 将优先级转换为掩码信号
  // 优先级以下的位置为0，优先级及以上的位置为1
  assign priority_mask = (~(16'hFFFF << (16 - priority_level)));
  
  // 根据优先级掩码对输入数据进行屏蔽处理
  // 只保留优先级及以上位置的数据
  always @(*) begin
    masked_data = data & ~priority_mask;
  end
  
  // 计算奇偶校验结果
  assign parity_result = ^masked_data;
endmodule