//SystemVerilog
module reset_done_generator (
  input wire clk,
  input wire reset_n,
  output reg reset_done
);
  // 增加流水线寄存器
  reg reset_n_stage1;
  reg reset_n_stage2;
  reg reset_n_stage3;
  reg reset_done_stage1;
  reg reset_done_stage2;
  
  always @(posedge clk) begin
    // 第一级流水线 - 捕获输入信号
    reset_n_stage1 <= !reset_n ? 1'b0 : reset_n;
      
    // 第二级流水线 - 传递信号
    reset_n_stage2 <= reset_n_stage1;
    
    // 第三级流水线 - 传递信号
    reset_n_stage3 <= reset_n_stage2;
    
    // 第四级流水线 - 生成reset_done_stage1
    reset_done_stage1 <= !reset_n_stage3 ? 1'b0 : 1'b1;
      
    // 第五级流水线 - 生成reset_done_stage2
    reset_done_stage2 <= reset_done_stage1;
    
    // 第六级流水线 - 生成最终输出
    reset_done <= reset_done_stage2;
  end
endmodule