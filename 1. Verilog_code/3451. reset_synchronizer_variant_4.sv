//SystemVerilog
module reset_synchronizer (
  input  wire clk,
  input  wire async_reset_n,
  output reg  sync_reset_n
);
  
  // 流水线寄存器 - 3级流水线用于更好的亚稳态恢复
  reg reset_stage1;
  reg reset_stage2;
  
  // 流水线控制信号
  reg pipeline_valid_stage1;
  reg pipeline_valid_stage2;
  reg pipeline_valid_stage3;
  
  // 第一级流水线 - 捕获异步复位到同步域
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      reset_stage1 <= 1'b0;
      pipeline_valid_stage1 <= 1'b0;
    end 
    else begin
      reset_stage1 <= 1'b1;
      pipeline_valid_stage1 <= 1'b1;
    end
  end
  
  // 第二级流水线 - 处理亚稳态
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      reset_stage2 <= 1'b0;
      pipeline_valid_stage2 <= 1'b0;
    end 
    else begin
      reset_stage2 <= reset_stage1;
      pipeline_valid_stage2 <= pipeline_valid_stage1;
    end
  end
  
  // 第三级流水线 - 输出稳定的同步复位信号
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      sync_reset_n <= 1'b0;
      pipeline_valid_stage3 <= 1'b0;
    end 
    else begin
      sync_reset_n <= reset_stage2;
      pipeline_valid_stage3 <= pipeline_valid_stage2;
    end
  end
  
endmodule