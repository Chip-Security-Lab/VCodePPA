//SystemVerilog
module power_on_reset #(
  parameter POR_CYCLES = 32
) (
  input wire clk,
  input wire power_good,
  output reg system_rst_n
);
  // 定义更细粒度的流水线寄存器和信号
  reg [$clog2(POR_CYCLES)-1:0] por_counter;
  wire [$clog2(POR_CYCLES)-1:0] target_count;
  
  // 拆分流水线阶段为更多级别
  reg [$clog2(POR_CYCLES)-1:0] inverted_counter_stage1;
  reg [$clog2(POR_CYCLES)-1:0] target_count_stage1;
  
  // 进一步拆分加法操作为两个阶段
  reg [$clog2(POR_CYCLES)/2-1:0] sum_low_stage2a;
  reg carry_low_stage2a;
  reg [$clog2(POR_CYCLES)/2-1:0] inverted_counter_high_stage2a;
  reg [$clog2(POR_CYCLES)/2-1:0] target_count_high_stage2a;
  
  reg [$clog2(POR_CYCLES)/2-1:0] sum_high_stage2b;
  reg carry_stage2b;
  
  // 完整的加法结果
  reg [$clog2(POR_CYCLES)-1:0] sum_stage3;
  reg carry_stage3;
  
  // 比较结果拆分
  reg zero_check_stage4a;
  reg carry_check_stage4a;
  
  reg comparison_stage4b;
  
  // 最终输出和控制信号
  reg comparison_stage5;
  
  // 常量定义
  assign target_count = POR_CYCLES - 1;
  wire [$clog2(POR_CYCLES)-1:0] inverted_counter = ~por_counter;
  
  // 流水线处理
  always @(posedge clk or negedge power_good) begin
    if (!power_good) begin
      // 复位所有流水线寄存器
      por_counter <= {($clog2(POR_CYCLES)){1'b0}};
      
      // 第一级流水线
      inverted_counter_stage1 <= {($clog2(POR_CYCLES)){1'b0}};
      target_count_stage1 <= {($clog2(POR_CYCLES)){1'b0}};
      
      // 第二级流水线 - 2a
      sum_low_stage2a <= {($clog2(POR_CYCLES)/2){1'b0}};
      carry_low_stage2a <= 1'b0;
      inverted_counter_high_stage2a <= {($clog2(POR_CYCLES)/2){1'b0}};
      target_count_high_stage2a <= {($clog2(POR_CYCLES)/2){1'b0}};
      
      // 第二级流水线 - 2b
      sum_high_stage2b <= {($clog2(POR_CYCLES)/2){1'b0}};
      carry_stage2b <= 1'b0;
      
      // 第三级流水线
      sum_stage3 <= {($clog2(POR_CYCLES)){1'b0}};
      carry_stage3 <= 1'b0;
      
      // 第四级流水线 - 4a
      zero_check_stage4a <= 1'b0;
      carry_check_stage4a <= 1'b0;
      
      // 第四级流水线 - 4b
      comparison_stage4b <= 1'b0;
      
      // 第五级流水线
      comparison_stage5 <= 1'b0;
      
      // 输出
      system_rst_n <= 1'b0;
    end else begin
      // 第一级流水线：保存反相计数器和目标计数值
      inverted_counter_stage1 <= inverted_counter;
      target_count_stage1 <= target_count;
      
      // 第二级流水线 - 2a：计算低位部分加法和准备高位数据
      {carry_low_stage2a, sum_low_stage2a} <= 
        inverted_counter_stage1[($clog2(POR_CYCLES)/2)-1:0] + 
        target_count_stage1[($clog2(POR_CYCLES)/2)-1:0] + 
        1'b1;
      
      inverted_counter_high_stage2a <= inverted_counter_stage1[$clog2(POR_CYCLES)-1:$clog2(POR_CYCLES)/2];
      target_count_high_stage2a <= target_count_stage1[$clog2(POR_CYCLES)-1:$clog2(POR_CYCLES)/2];
      
      // 第二级流水线 - 2b：计算高位部分加法
      {carry_stage2b, sum_high_stage2b} <= 
        inverted_counter_high_stage2a + 
        target_count_high_stage2a + 
        carry_low_stage2a;
      
      // 第三级流水线：组合完整的加法结果
      sum_stage3 <= {sum_high_stage2b, sum_low_stage2a};
      carry_stage3 <= carry_stage2b;
      
      // 第四级流水线 - 4a：检查零和进位
      zero_check_stage4a <= (sum_stage3 == {($clog2(POR_CYCLES)){1'b0}});
      carry_check_stage4a <= carry_stage3;
      
      // 第四级流水线 - 4b：完成比较操作
      comparison_stage4b <= zero_check_stage4a && carry_check_stage4a;
      
      // 第五级流水线：最终控制信号
      comparison_stage5 <= comparison_stage4b;
      
      // 更新计数器和输出
      if (!comparison_stage5) 
        por_counter <= por_counter + 1'b1;
      
      // 最终输出结果
      system_rst_n <= comparison_stage5;
    end
  end
endmodule