//SystemVerilog
module RD10 #(parameter BITS=8)(
  input clk, input rst, input en,
  input [BITS-1:0] in_val,
  output reg [BITS-1:0] out_val
);
  // 使用查找表辅助减法器实现
  reg [BITS-1:0] lut_table [0:255];  // 8位减法的查找表
  wire [BITS-1:0] sub_result;
  
  // 查找表初始化 - 使用initial块预计算所有可能的减法结果
  integer idx;
  initial begin
    for (idx = 0; idx < 256; idx = idx + 1) begin
      lut_table[idx] = 8'd10 - idx[7:0];  // 预计算10减去每个可能的输入值
    end
  end
  
  // 通过查找表获取减法结果
  assign sub_result = lut_table[in_val];
  
  // 输出寄存器
  always @(posedge clk) begin
    if (rst)
      out_val <= {BITS{1'b0}};
    else if (en)
      out_val <= sub_result;
    else
      out_val <= out_val;  // 保持当前值，而非清零
  end
endmodule