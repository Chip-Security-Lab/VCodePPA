//SystemVerilog
module edge_reset_monitor (
  input  wire clk,
  input  wire reset_n,
  output reg  reset_edge_detected
);
  // 流水线寄存器
  reg reset_n_stage1;
  reg reset_n_stage2;
  reg reset_n_prev_stage1;
  reg reset_n_prev_stage2;
  
  // 流水线有效信号
  reg valid_stage1;
  reg valid_stage2;
  
  // 流水线阶段1: 采样输入信号
  always @(posedge clk) begin
    reset_n_stage1 <= reset_n;
    valid_stage1 <= 1'b1; // 流水线总是有效
  end
  
  // 流水线阶段2: 检测边沿
  always @(posedge clk) begin
    reset_n_stage2 <= reset_n_stage1;
    reset_n_prev_stage1 <= reset_n_stage1;
    valid_stage2 <= valid_stage1;
  end
  
  // 流水线阶段3: 产生输出
  always @(posedge clk) begin
    if (valid_stage2) begin
      reset_edge_detected <= ~reset_n_stage2 & reset_n_prev_stage1;
    end
  end
endmodule