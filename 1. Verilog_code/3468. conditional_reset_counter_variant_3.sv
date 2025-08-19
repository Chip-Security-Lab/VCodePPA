//SystemVerilog
module conditional_reset_counter #(parameter WIDTH = 12)(
  input wire clk, reset_n, condition, enable,
  output reg [WIDTH-1:0] value,
  // 流水线控制接口
  input wire in_valid,
  output wire in_ready,
  output reg out_valid,
  input wire out_ready
);
  
  // 流水线级数定义
  localparam PIPELINE_STAGES = 3;
  
  // 流水线寄存器
  reg [WIDTH-1:0] value_stage1, value_stage2;
  reg reset_signal_stage1, reset_signal_stage2;
  reg enable_stage1, enable_stage2;
  reg valid_stage1, valid_stage2;
  
  // 流水线控制逻辑
  wire pipe_ready;
  assign pipe_ready = !out_valid || out_ready;
  assign in_ready = pipe_ready;
  
  // 第一级流水线：计算复位信号
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_signal_stage1 <= 1'b1;
      enable_stage1 <= 1'b0;
      value_stage1 <= {WIDTH{1'b0}};
      valid_stage1 <= 1'b0;
    end
    else if (pipe_ready) begin
      reset_signal_stage1 <= !reset_n || (condition && enable);
      enable_stage1 <= enable;
      value_stage1 <= value;
      valid_stage1 <= in_valid;
    end
  end
  
  // 第二级流水线：更新计数值
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      reset_signal_stage2 <= 1'b1;
      enable_stage2 <= 1'b0;
      value_stage2 <= {WIDTH{1'b0}};
      valid_stage2 <= 1'b0;
    end
    else if (pipe_ready) begin
      reset_signal_stage2 <= reset_signal_stage1;
      enable_stage2 <= enable_stage1;
      
      if (reset_signal_stage1)
        value_stage2 <= {WIDTH{1'b0}};
      else if (enable_stage1)
        value_stage2 <= value_stage1 + 1'b1;
      else
        value_stage2 <= value_stage1;
        
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 第三级流水线：输出结果
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      value <= {WIDTH{1'b0}};
      out_valid <= 1'b0;
    end
    else if (pipe_ready) begin
      value <= value_stage2;
      out_valid <= valid_stage2;
    end
  end
  
endmodule