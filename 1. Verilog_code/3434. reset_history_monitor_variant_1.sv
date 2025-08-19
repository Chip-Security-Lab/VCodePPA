//SystemVerilog
module reset_history_monitor (
  input wire clk,
  input wire reset_n,
  input wire reset_in,
  input wire clear,
  input wire valid_in,
  output wire valid_out,
  output reg [7:0] reset_history
);
  // 流水线寄存器 - 阶段1
  reg reset_in_stage1;
  reg reset_in_d_stage1;
  reg clear_stage1;
  reg valid_stage1;
  
  // 流水线寄存器 - 阶段2
  reg reset_edge_detected_stage2;
  reg clear_stage2;
  reg valid_stage2;
  reg [7:0] reset_history_stage2;
  
  // 流水线寄存器 - 阶段3
  reg valid_stage3;
  reg [7:0] reset_history_stage3;
  
  // 流水线状态跟踪
  reg [2:0] pipeline_active;
  
  // 流水线阶段1: 边沿检测逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_in_stage1 <= 1'b0;
      reset_in_d_stage1 <= 1'b0;
      clear_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
      pipeline_active[0] <= 1'b0;
    end else begin
      reset_in_stage1 <= reset_in;
      reset_in_d_stage1 <= reset_in_stage1;
      clear_stage1 <= clear;
      valid_stage1 <= valid_in;
      pipeline_active[0] <= valid_in;
    end
  end
  
  // 流水线阶段2: 更新历史记录
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_edge_detected_stage2 <= 1'b0;
      clear_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
      reset_history_stage2 <= 8'h00;
      pipeline_active[1] <= 1'b0;
    end else begin
      // 边沿检测
      reset_edge_detected_stage2 <= reset_in_stage1 && !reset_in_d_stage1;
      clear_stage2 <= clear_stage1;
      valid_stage2 <= valid_stage1;
      pipeline_active[1] <= pipeline_active[0];
      
      // 计算下一个历史值
      if (valid_stage1) begin
        if (clear_stage1)
          reset_history_stage2 <= 8'h00;
        else if (reset_in_stage1 && !reset_in_d_stage1)
          reset_history_stage2 <= {reset_history[6:0], 1'b1};
        else
          reset_history_stage2 <= reset_history;
      end
    end
  end
  
  // 流水线阶段3: 最终处理和输出结果
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_history <= 8'h00;
      valid_stage3 <= 1'b0;
      reset_history_stage3 <= 8'h00;
      pipeline_active[2] <= 1'b0;
    end else begin
      valid_stage3 <= valid_stage2;
      pipeline_active[2] <= pipeline_active[1];
      
      // 最终处理
      if (valid_stage2) begin
        reset_history_stage3 <= reset_history_stage2;
      end
      
      // 输出到最终寄存器
      if (valid_stage3) begin
        reset_history <= reset_history_stage3;
      end
    end
  end
  
  // 定义输出有效信号
  assign valid_out = valid_stage3;
  
endmodule