//SystemVerilog
module freq_sensitive_reset #(
  parameter CLOCK_COUNT = 8
) (
  input wire main_clk,
  input wire ref_clk,
  input wire rst_n,
  output wire reset_out
);
  // 直接捕获输入信号而不是先同步
  reg ref_clk_direct;
  reg ref_clk_prev;
  
  // 流水线第一级 - 边沿检测已移动到组合逻辑后
  wire edge_detected_comb;
  reg edge_detected_stage1;
  
  // 流水线第二级
  reg edge_detected_stage2;
  reg [3:0] main_counter_stage2;
  reg [3:0] ref_counter_stage2;
  
  // 流水线第三级
  reg [3:0] main_counter_stage3;
  reg [3:0] ref_counter_stage3;
  reg reset_condition_stage3;
  
  // 流水线第四级
  reg reset_out_reg;
  
  // 流水线阶段控制信号
  reg valid_stage1, valid_stage2, valid_stage3, valid_stage4;
  
  // 前向重定时：直接捕获输入信号
  always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
      ref_clk_direct <= 1'b0;
      ref_clk_prev <= 1'b0;
    end else begin
      ref_clk_direct <= ref_clk;
      ref_clk_prev <= ref_clk_direct;
    end
  end
  
  // 组合逻辑检测边沿，将检测移到寄存器前
  assign edge_detected_comb = ref_clk_direct && !ref_clk_prev;
  
  // 流水线第一级 - 将边沿检测后移到组合逻辑之后
  always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
      edge_detected_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      edge_detected_stage1 <= edge_detected_comb; // 捕获组合逻辑的结果
      valid_stage1 <= 1'b1;
    end
  end
  
  // 流水线第二级 - 准备计数器控制
  always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
      edge_detected_stage2 <= 1'b0;
      main_counter_stage2 <= 4'd0;
      ref_counter_stage2 <= 4'd0;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      edge_detected_stage2 <= edge_detected_stage1;
      main_counter_stage2 <= main_counter_stage3; // 反馈路径
      ref_counter_stage2 <= ref_counter_stage3;   // 反馈路径
      valid_stage2 <= valid_stage1;
    end
  end
  
  // 流水线第三级 - 更新计数器和比较
  always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
      main_counter_stage3 <= 4'd0;
      ref_counter_stage3 <= 4'd0;
      reset_condition_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else if (valid_stage2) begin
      if (edge_detected_stage2) begin
        main_counter_stage3 <= 4'd0;
        ref_counter_stage3 <= ref_counter_stage2 + 4'd1;
      end else if (main_counter_stage2 < 4'hF) begin
        main_counter_stage3 <= main_counter_stage2 + 4'd1;
        ref_counter_stage3 <= ref_counter_stage2;
      end else begin
        main_counter_stage3 <= main_counter_stage2;
        ref_counter_stage3 <= ref_counter_stage2;
      end
      reset_condition_stage3 <= (main_counter_stage2 > CLOCK_COUNT);
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 流水线第四级 - 输出寄存器
  always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
      reset_out_reg <= 1'b0;
      valid_stage4 <= 1'b0;
    end else if (valid_stage3) begin
      reset_out_reg <= reset_condition_stage3;
      valid_stage4 <= valid_stage3;
    end
  end

  // 输出赋值
  assign reset_out = reset_out_reg;
  
endmodule