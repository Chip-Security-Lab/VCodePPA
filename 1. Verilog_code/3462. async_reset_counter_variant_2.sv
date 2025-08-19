//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module async_reset_counter #(parameter WIDTH = 16)(
  input clk, rst_n, enable,
  output reg [WIDTH-1:0] counter
);
  
  // 注册输入信号
  reg enable_reg;
  reg [WIDTH-1:0] counter_next;
  
  // 捕获输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      enable_reg <= 1'b0;
    end else begin
      enable_reg <= enable;
    end
  end
  
  // 预计算下一个计数器状态
  always @(*) begin
    counter_next = enable_reg ? (counter + 1'b1) : counter;
  end
  
  // 更新计数器值
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 异步复位情况
      counter <= {WIDTH{1'b0}};
    end else begin
      // 使用预计算的值
      counter <= counter_next;
    end
  end
  
endmodule