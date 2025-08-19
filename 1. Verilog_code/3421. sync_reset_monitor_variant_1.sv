//SystemVerilog
module sync_reset_monitor (
  input wire clk,
  input wire reset_n,
  output reg reset_stable
);
  // 扩展流水线深度，从6级扩展到9级
  reg [5:0] reset_shift_stage1;
  reg [5:0] reset_shift_stage2;
  reg [2:0] reset_stable_stage3;
  reg [2:0] reset_stable_stage4;
  reg [1:0] reset_stable_stage5;
  reg [1:0] reset_stable_stage6;
  reg reset_stable_stage7;
  reg reset_stable_stage8;
  
  always @(posedge clk) begin
    // 第一级流水线 - 采样输入信号
    reset_shift_stage1 <= {reset_shift_stage1[4:0], reset_n};
    
    // 第二级流水线 - 缓存第一级结果，减轻组合逻辑负担
    reset_shift_stage2 <= reset_shift_stage1;
    
    // 第三级流水线 - 处理信号
    reset_stable_stage3[0] <= reset_shift_stage2[0] & reset_shift_stage2[1];
    reset_stable_stage3[1] <= reset_shift_stage2[2] & reset_shift_stage2[3];
    reset_stable_stage3[2] <= reset_shift_stage2[4] & reset_shift_stage2[5];
    
    // 第四级流水线 - 缓存第三级结果
    reset_stable_stage4 <= reset_stable_stage3;
    
    // 第五级流水线 - 进一步处理结果
    reset_stable_stage5[0] <= reset_stable_stage4[0] & reset_stable_stage4[1];
    reset_stable_stage5[1] <= reset_stable_stage4[2];
    
    // 第六级流水线 - 缓存第五级结果
    reset_stable_stage6 <= reset_stable_stage5;
    
    // 第七级流水线 - 处理最终结果
    reset_stable_stage7 <= reset_stable_stage6[0] & reset_stable_stage6[1];
    
    // 第八级流水线 - 缓存第七级结果
    reset_stable_stage8 <= reset_stable_stage7;
    
    // 第九级流水线 - 输出最终结果
    reset_stable <= reset_stable_stage8;
  end
endmodule