//SystemVerilog
module reset_sync_comb_out(
  input  wire clk,
  input  wire rst_in,
  output wire rst_out
);
  // 移动寄存器位置，推进到组合逻辑之后
  // 优化后的流水线寄存器
  reg flop_inter, flop_stage2, flop_stage3;
  
  // 优化后的有效信号寄存器
  reg valid_inter, valid_stage2, valid_stage3;
  
  // 输入端直接处理的组合逻辑信号
  wire stage1_data = 1'b1;
  wire stage1_valid = 1'b1;
  
  // 重构的流水线控制
  always @(posedge clk or negedge rst_in) begin
    if(!rst_in) begin
      // 重置所有流水线寄存器
      flop_inter <= 1'b0;
      flop_stage2 <= 1'b0;
      flop_stage3 <= 1'b0;
      
      // 重置有效信号寄存器
      valid_inter <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      // 中间寄存器 - 已将第一级寄存器移至组合逻辑之后
      flop_inter <= stage1_data;
      valid_inter <= stage1_valid;
      
      // 流水线第二级
      flop_stage2 <= flop_inter;
      valid_stage2 <= valid_inter;
      
      // 流水线第三级
      flop_stage3 <= flop_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // 优化的输出生成逻辑
  assign rst_out = (flop_stage2 & flop_stage3) & valid_stage3;
endmodule