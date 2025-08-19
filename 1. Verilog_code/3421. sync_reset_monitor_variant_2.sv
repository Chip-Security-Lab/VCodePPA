//SystemVerilog
module sync_reset_monitor (
  input  wire clk,         // 系统时钟
  input  wire reset_n,     // 异步复位信号（低电平有效）
  output wire reset_stable // 稳定的同步复位指示（高电平表示稳定）
);
  // 复位检测流水线级信号
  reg [2:0] reset_history_stage1;    // 第一级流水线 - 复位历史
  reg       reset_valid_stage1;      // 第一级流水线 - 有效信号
  
  reg [2:0] reset_history_stage2;    // 第二级流水线 - 缓存的复位历史
  reg       reset_valid_stage2;      // 第二级流水线 - 有效信号
  
  reg       reset_stable_stage3;     // 第三级流水线 - 分析结果
  reg       reset_valid_stage3;      // 第三级流水线 - 有效信号
  
  // 流水线重置控制
  reg       pipeline_active;         // 流水线激活状态

  // 第一级流水线 - 采样复位信号
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_history_stage1 <= 3'b000;
      reset_valid_stage1 <= 1'b0;
      pipeline_active <= 1'b0;
    end else begin
      reset_history_stage1 <= {reset_history_stage1[1:0], reset_n};
      reset_valid_stage1 <= 1'b1;
      pipeline_active <= 1'b1;
    end
  end
  
  // 第二级流水线 - 缓存复位信号历史
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_history_stage2 <= 3'b000;
      reset_valid_stage2 <= 1'b0;
    end else if (pipeline_active) begin
      reset_history_stage2 <= reset_history_stage1;
      reset_valid_stage2 <= reset_valid_stage1;
    end
  end
  
  // 第三级流水线 - 分析稳定性
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_stable_stage3 <= 1'b0;
      reset_valid_stage3 <= 1'b0;
    end else if (pipeline_active) begin
      reset_stable_stage3 <= &reset_history_stage2;
      reset_valid_stage3 <= reset_valid_stage2;
    end
  end
  
  // 输出分配 - 只有当流水线有效时才输出稳定状态
  assign reset_stable = reset_valid_stage3 ? reset_stable_stage3 : 1'b0;
  
endmodule