//SystemVerilog
module external_reset_validator (
  input wire clk,
  input wire ext_reset,
  input wire validation_en,
  output reg valid_reset,
  output reg invalid_reset
);
  // 流水线寄存器
  reg [1:0] ext_reset_sync;
  reg validation_en_stage1;
  reg validation_en_stage2;
  reg ext_reset_stage2;
  reg ext_reset_stage3;
  
  // Stage 1: 输入同步和捕获
  always @(posedge clk) begin
    // 两级同步器用于ext_reset
    ext_reset_sync <= {ext_reset_sync[0], ext_reset};
    // 捕获validation_en信号
    validation_en_stage1 <= validation_en;
  end
  
  // Stage 2: 数据准备阶段
  always @(posedge clk) begin
    // 传递同步后的复位信号到下一级
    ext_reset_stage2 <= ext_reset_sync[1];
    // 传递验证使能信号到下一级
    validation_en_stage2 <= validation_en_stage1;
  end
  
  // Stage 3: 输出计算阶段
  always @(posedge clk) begin
    // 将同步复位信号传递到最后阶段
    ext_reset_stage3 <= ext_reset_stage2;
    
    // 计算最终输出
    valid_reset <= ext_reset_stage3 & validation_en_stage2;
    invalid_reset <= ext_reset_stage3 & ~validation_en_stage2;
  end
endmodule