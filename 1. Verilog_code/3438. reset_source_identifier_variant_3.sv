//SystemVerilog
//IEEE 1364-2005
module reset_source_identifier (
  input wire clk,
  input wire sys_reset,
  input wire pwr_reset,
  input wire wdt_reset,
  input wire sw_reset,
  output reg [3:0] reset_source
);
  
  // 中间变量，用于决策树结构
  reg [3:0] next_reset_source;
  
  // 组合逻辑部分 - 决策树结构
  always @(*) begin
    // 默认值
    next_reset_source = 4'h0;
    
    // 按优先级评估复位源
    if (pwr_reset) begin
      next_reset_source = 4'h1;
    end else if (wdt_reset) begin
      next_reset_source = 4'h2;
    end else if (sw_reset) begin
      next_reset_source = 4'h3;
    end else if (sys_reset) begin
      next_reset_source = 4'h4;
    end
    // 当没有复位信号时，next_reset_source保持默认值4'h0
  end
  
  // 时序逻辑部分
  always @(posedge clk) begin
    reset_source <= next_reset_source;
  end
  
endmodule