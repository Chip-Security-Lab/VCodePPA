//SystemVerilog
module reset_glitch_detector (
  input wire clk,
  input wire reset_n,
  output reg glitch_detected
);
  
  // 减少流水线级数，只保留两级
  reg reset_stage1;
  reg reset_stage2;
  
  // 第一级流水线 - 捕获输入并进行比较
  always @(posedge clk) begin
    reset_stage1 <= reset_n;
    reset_stage2 <= reset_stage1;
  end
  
  // 第二级流水线 - 直接检测边沿并输出结果
  always @(posedge clk) begin
    glitch_detected <= (reset_stage1 != reset_stage2);
  end
  
endmodule