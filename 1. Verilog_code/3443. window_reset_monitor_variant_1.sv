//SystemVerilog
module window_reset_monitor #(
  parameter MIN_WINDOW = 4,
  parameter MAX_WINDOW = 12
) (
  input wire clk,
  input wire reset_pulse,
  output reg valid_reset
);
  // 流水线阶段寄存器
  reg reset_pulse_stage1, reset_pulse_stage2;
  reg reset_active_stage1, reset_active_stage2, reset_active_stage3;
  reg [$clog2(MAX_WINDOW):0] window_counter_stage1, window_counter_stage2, window_counter_stage3;
  reg window_min_check, window_max_check;
  
  // 合并所有阶段处理逻辑至单一always块
  always @(posedge clk) begin
    // 阶段1：捕获输入并开始处理
    reset_pulse_stage1 <= reset_pulse;
    if (reset_pulse && !reset_active_stage1) begin
      reset_active_stage1 <= 1'b1;
      window_counter_stage1 <= 0;
    end else if (reset_active_stage1) begin
      window_counter_stage1 <= window_counter_stage1 + 1;
      if (!reset_pulse) begin
        reset_active_stage1 <= 1'b0;
      end
    end
    
    // 阶段2：继续计数和检测处理
    reset_pulse_stage2 <= reset_pulse_stage1;
    reset_active_stage2 <= reset_active_stage1;
    window_counter_stage2 <= window_counter_stage1;
    
    // 阶段3：完成处理并准备输出
    reset_active_stage3 <= reset_active_stage2;
    window_counter_stage3 <= window_counter_stage2;
    
    // 窗口范围检查
    window_min_check <= (window_counter_stage2 >= MIN_WINDOW);
    window_max_check <= (window_counter_stage2 <= MAX_WINDOW);
    
    // 阶段4：输出生成
    if (reset_active_stage2 && !reset_pulse_stage2 && !reset_active_stage3) begin
      valid_reset <= window_min_check && window_max_check;
    end
  end
endmodule