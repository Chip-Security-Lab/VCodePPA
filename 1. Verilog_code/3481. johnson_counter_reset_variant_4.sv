//SystemVerilog
module johnson_counter_reset #(
  parameter WIDTH = 8
)(
  input wire clk,      // 时钟输入
  input wire rst,      // 复位信号
  input wire enable,   // 使能信号
  output reg [WIDTH-1:0] johnson_count // 约翰逊计数器输出
);

  // 复位初始值优化为常量，避免动态生成
  localparam [WIDTH-1:0] RESET_VALUE = {{WIDTH-1{1'b0}}, 1'b1};
  
  // 寄存器重定时：添加组合逻辑端寄存器
  reg inverted_msb;
  
  // 将取反操作放在寄存器之前，实现后向寄存器重定时
  always @(posedge clk) begin
    if (rst) begin
      inverted_msb <= ~RESET_VALUE[WIDTH-1];
    end 
    else if (enable) begin
      inverted_msb <= ~johnson_count[WIDTH-1];
    end
  end
  
  // 主计数器逻辑
  always @(posedge clk) begin
    if (rst) begin
      johnson_count <= RESET_VALUE;
    end 
    else if (enable) begin
      // 使用预先计算的取反位，减少关键路径延迟
      johnson_count <= {johnson_count[WIDTH-2:0], inverted_msb};
    end
  end

endmodule