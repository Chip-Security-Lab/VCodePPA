//SystemVerilog
module async_reset_counter #(
  parameter WIDTH = 16
)(
  input  wire            clk,     // 系统时钟
  input  wire            rst_n,   // 异步低电平复位
  input  wire            enable,  // 计数使能信号
  output reg  [WIDTH-1:0] counter // 计数器输出
);

  // 内部信号声明
  reg [WIDTH-1:0] counter_next;   // 下一个计数值
  reg             count_enable;   // 寄存的使能信号
  
  // 第一级：处理控制信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count_enable <= 1'b0;
    end else begin
      count_enable <= enable;
    end
  end
  
  // 第二级：计算下一个计数值（组合逻辑）
  always @(*) begin
    counter_next = count_enable ? counter + 1'b1 : counter;
  end
  
  // 第三级：更新计数器状态
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= {WIDTH{1'b0}};
    end else begin
      counter <= counter_next;
    end
  end

endmodule