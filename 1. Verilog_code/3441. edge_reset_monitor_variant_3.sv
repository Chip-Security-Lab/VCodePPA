//SystemVerilog
module edge_reset_monitor (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_edge_detected
);
  // 复位信号同步捕获流水线
  reg reset_n_sync_stage1;
  reg reset_n_sync_stage2;
  reg reset_n_history;  // 存储前一个状态用于边沿检测
  
  // 边沿检测和控制逻辑流水线
  wire rising_edge_detected;  // 更清晰的命名表示检测到的是上升沿
  
  // 优化的边沿检测组合逻辑 - 检测复位信号的上升沿
  assign rising_edge_detected = ~reset_n_history & reset_n_sync_stage2;
  
  always @(posedge clk) begin
    // 数据同步阶段 - 捕获和同步输入信号
    reset_n_sync_stage1 <= reset_n;            // 第一级同步器
    reset_n_sync_stage2 <= reset_n_sync_stage1; // 第二级同步器
    
    // 状态保存阶段 - 保存历史值用于边沿比较
    reset_n_history <= reset_n_sync_stage2;
    
    // 输出驱动阶段 - 更新输出信号
    reset_edge_detected <= rising_edge_detected;
  end
endmodule