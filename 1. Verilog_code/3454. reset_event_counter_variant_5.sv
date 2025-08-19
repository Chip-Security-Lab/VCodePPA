//SystemVerilog
module reset_event_counter (
  input wire clk,
  input wire reset_n,
  output reg [7:0] reset_count
);
  // 流水线寄存器
  reg reset_n_stage1, reset_n_stage2;
  reg valid_stage1, valid_stage2;
  reg [7:0] count_stage1, count_stage2;
  
  // 第一级流水线 - 检测复位事件
  always @(posedge clk) begin
    reset_n_stage1 <= reset_n;
    valid_stage1 <= 1'b1; // 第一级始终有效
  end
  
  // 第二级流水线 - 计算下一个计数值
  always @(posedge clk) begin
    reset_n_stage2 <= reset_n_stage1;
    valid_stage2 <= valid_stage1;
    
    if (valid_stage1) begin
      if (!reset_n_stage1)
        count_stage1 <= reset_count + 1;
      else
        count_stage1 <= reset_count;
    end
  end
  
  // 第三级流水线 - 更新输出计数器
  always @(posedge clk) begin
    if (valid_stage2) begin
      count_stage2 <= count_stage1;
      reset_count <= count_stage2;
    end
  end
endmodule