//SystemVerilog
//IEEE 1364-2005 Verilog
module freq_sensitive_reset #(
  parameter CLOCK_COUNT = 8
) (
  input wire main_clk,
  input wire ref_clk,
  output reg reset_out
);
  // 移动ref_clk_sync寄存器到组合逻辑后
  reg ref_clk_delayed;  // 用于捕获ref_clk的值
  wire ref_clk_posedge; // 检测上升沿
  
  reg [3:0] main_counter;
  reg [3:0] ref_counter;
  
  // 并行前缀加法器信号声明
  wire [3:0] p_main, g_main;  // 传播(propagate)和生成(generate)信号
  wire [3:0] c_main;          // 进位信号
  wire [3:0] main_sum;        // 加法结果

  wire [3:0] p_ref, g_ref;    // ref计数器的传播和生成信号
  wire [3:0] c_ref;           // ref计数器的进位信号  
  wire [3:0] ref_sum;         // ref计数器加法结果
  
  // 主计数器并行前缀加法器实现
  // 第一阶段：计算位传播和生成信号
  assign p_main = main_counter;
  assign g_main = 4'b0;
  
  // 第二阶段：计算并行前缀
  assign c_main[0] = 1'b1;                    // 加1操作的初始进位
  assign c_main[1] = g_main[0] | (p_main[0] & c_main[0]);
  assign c_main[2] = g_main[1] | (p_main[1] & g_main[0]) | (p_main[1] & p_main[0] & c_main[0]);
  assign c_main[3] = g_main[2] | (p_main[2] & g_main[1]) | (p_main[2] & p_main[1] & g_main[0]) | (p_main[2] & p_main[1] & p_main[0] & c_main[0]);
  
  // 第三阶段：计算最终和
  assign main_sum = main_counter ^ c_main;
  
  // 参考计数器并行前缀加法器实现
  // 第一阶段：计算位传播和生成信号
  assign p_ref = ref_counter;
  assign g_ref = 4'b0;
  
  // 第二阶段：计算并行前缀
  assign c_ref[0] = 1'b1;                   // 加1操作的初始进位
  assign c_ref[1] = g_ref[0] | (p_ref[0] & c_ref[0]);
  assign c_ref[2] = g_ref[1] | (p_ref[1] & g_ref[0]) | (p_ref[1] & p_ref[0] & c_ref[0]);
  assign c_ref[3] = g_ref[2] | (p_ref[2] & g_ref[1]) | (p_ref[2] & p_ref[1] & g_ref[0]) | (p_ref[2] & p_ref[1] & p_ref[0] & c_ref[0]);
  
  // 第三阶段：计算最终和
  assign ref_sum = ref_counter ^ c_ref;
  
  // 优化后的上升沿检测逻辑
  always @(posedge main_clk) begin
    ref_clk_delayed <= ref_clk;
  end
  
  // 检测上升沿
  assign ref_clk_posedge = ref_clk && !ref_clk_delayed;
  
  // 主逻辑 - 根据前向寄存器重定时优化
  always @(posedge main_clk) begin
    if (ref_clk_posedge) begin
      main_counter <= 4'd0;
      ref_counter <= ref_sum;
    end else if (main_counter < 4'hF) begin
      main_counter <= main_sum;
    end
    
    // 输出逻辑单独处理，降低关键路径延迟
    reset_out <= (main_counter > CLOCK_COUNT);
  end
endmodule