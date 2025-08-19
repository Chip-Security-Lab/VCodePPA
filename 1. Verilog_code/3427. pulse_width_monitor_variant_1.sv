//SystemVerilog
module pulse_width_monitor #(
  parameter MIN_WIDTH = 4
) (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_valid
);
  // 定义阶段寄存器
  reg reset_in_d;
  reg [$clog2(MIN_WIDTH)-1:0] width_counter;
  reg pulse_active;
  
  // 优化的边沿检测
  wire pulse_start = reset_in && !reset_in_d;
  
  // 优化的比较逻辑 - 使用固定目标值比较
  wire min_width_reached = (width_counter == (MIN_WIDTH-1));
  
  always @(posedge clk) begin
    // 边沿检测寄存器更新
    reset_in_d <= reset_in;
    
    // 优化后的计数器逻辑
    if (pulse_start) begin
      // 重置计数器并启动脉冲监测
      width_counter <= 'd0;
      pulse_active <= 1'b1;
    end else if (pulse_active) begin
      if (!reset_in) begin
        // 脉冲提前终止
        pulse_active <= 1'b0;
      end else if (!min_width_reached) begin
        // 继续计数
        width_counter <= width_counter + 1'b1;
      end
    end
    
    // 优化的有效信号生成 - 直接在单个周期内确定
    reset_valid <= reset_in && pulse_active && min_width_reached;
  end
endmodule