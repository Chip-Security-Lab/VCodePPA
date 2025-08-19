//SystemVerilog
module timeout_counter #(parameter TIMEOUT = 100)(
  input clk, manual_rst, enable,
  output reg timeout_flag
);
  
  // Pipeline stage registers
  reg [$clog2(TIMEOUT):0] counter_stage1;
  reg manual_rst_stage1, enable_stage1;
  reg timeout_pending_stage1;
  
  reg [$clog2(TIMEOUT):0] counter_stage2;
  reg manual_rst_stage2, enable_stage2;
  reg timeout_pending_stage2;
  
  // 第一阶段：输入信号捕获
  always @(posedge clk) begin
    manual_rst_stage1 <= manual_rst;
    enable_stage1 <= enable;
  end
  
  // 第一阶段：计数器控制逻辑
  always @(posedge clk) begin
    if (manual_rst) begin
      counter_stage1 <= 0;
      timeout_pending_stage1 <= 0;
    end 
    else if (enable) begin
      if (counter_stage1 >= TIMEOUT - 1) begin
        counter_stage1 <= 0;
        timeout_pending_stage1 <= 1;
      end 
      else begin
        counter_stage1 <= counter_stage1 + 1;
        timeout_pending_stage1 <= 0;
      end
    end
  end
  
  // 第二阶段：状态传播
  always @(posedge clk) begin
    manual_rst_stage2 <= manual_rst_stage1;
    enable_stage2 <= enable_stage1;
    counter_stage2 <= counter_stage1;
    timeout_pending_stage2 <= timeout_pending_stage1;
  end
  
  // 第二阶段：超时标志生成
  always @(posedge clk) begin
    if (manual_rst_stage2) begin
      timeout_flag <= 0;
    end 
    else if (enable_stage2) begin
      timeout_flag <= timeout_pending_stage2;
    end
  end
  
endmodule