//SystemVerilog
module reset_pattern_detector (
  input wire clk,
  input wire reset_sig,
  output reg pattern_detected
);
  // 数据采集阶段 - 移位寄存器
  reg [7:0] shift_reg;
  reg [7:0] pattern_buffer;
  
  // 模式定义
  localparam PATTERN = 8'b10101010;
  
  // 分级流水线处理
  // 第一级：数据采集
  always @(posedge clk) begin
    shift_reg <= {shift_reg[6:0], reset_sig};
  end
  
  // 第二级：模式缓存
  always @(posedge clk) begin
    pattern_buffer <= shift_reg;
  end
  
  // 第三级：模式比较和结果输出
  always @(posedge clk) begin
    pattern_detected <= (pattern_buffer == PATTERN);
  end
endmodule