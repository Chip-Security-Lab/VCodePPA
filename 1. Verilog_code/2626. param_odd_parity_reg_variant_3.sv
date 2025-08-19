//SystemVerilog
module param_odd_parity_reg #(
  parameter DATA_W = 32
)(
  input clk,
  input [DATA_W-1:0] data,
  output reg parity_bit
);
  // 曼彻斯特进位链加法器实现
  reg [7:0] lut_parity [0:255]; // 8位查找表
  reg [3:0] partial_parity;     // 存储部分校验结果
  reg [7:0] sum;                // 曼彻斯特加法器的和
  reg carry;                   // 进位信号
  integer i;

  // 初始化查找表
  initial begin
    for (i = 0; i < 256; i = i + 1) begin
      lut_parity[i] = ^i; // 预计算每个8位组合的奇偶校验
    end
  end

  // 曼彻斯特进位链加法器计算
  always @(posedge clk) begin
    partial_parity = 0;
    carry = 0;
    for (i = 0; i < (DATA_W/8); i = i + 1) begin
      {carry, sum} = lut_parity[data[i*8+:8]] + partial_parity; // 曼彻斯特加法
      partial_parity = sum ^ carry; // 更新部分校验结果
    end

    // 处理剩余的位
    if (DATA_W % 8 != 0) begin
      partial_parity = partial_parity ^ (^data[DATA_W-1:DATA_W-(DATA_W%8)]);
    end

    // 计算偶校验位
    parity_bit <= ~partial_parity;
  end
endmodule