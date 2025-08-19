//SystemVerilog
module reset_pattern_detector (
  input  wire clk,
  input  wire reset_sig,
  output reg  pattern_detected
);
  // 数据流阶段1: 输入缓存与移位寄存器
  reg [6:0] shift_reg;
  reg reset_sig_r;
  
  // 数据流阶段2: 模式比较逻辑
  reg [7:0] pattern_buffer;
  wire pattern_match;
  
  // 目标模式常量
  localparam PATTERN = 8'b10101010;
  
  // 阶段1: 捕获输入数据
  always @(posedge clk) begin
    reset_sig_r <= reset_sig;
    shift_reg <= shift_reg[5:0] << 1 | reset_sig_r;
  end
  
  // 阶段2: 构建完整模式并检测
  always @(posedge clk) begin
    pattern_buffer <= {shift_reg, reset_sig};
  end
  
  // 阶段3: 模式匹配逻辑 - 将组合逻辑分离为独立单元
  assign pattern_match = (pattern_buffer == PATTERN);
  
  // 阶段4: 输出寄存器 - 防止毛刺传播
  always @(posedge clk) begin
    pattern_detected <= pattern_match;
  end
  
endmodule