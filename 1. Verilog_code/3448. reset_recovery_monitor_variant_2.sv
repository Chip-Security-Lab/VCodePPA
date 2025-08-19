//SystemVerilog
module reset_recovery_monitor #(
  parameter MIN_STABLE_CYCLES = 16
) (
  input wire clk,
  input wire reset_n,
  output reg system_stable
);
  
  // 使用两个计数器阶段，减少不必要的流水线级数
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] stable_counter;
  reg [$clog2(MIN_STABLE_CYCLES)-1:0] counter_compare;
  
  // 中间稳定状态信号
  reg stable_condition;
  reg stable_condition_pipe;
  
  // 计数器更新 - 第一级组合逻辑处理
  wire [$clog2(MIN_STABLE_CYCLES)-1:0] next_counter = 
    (stable_counter < MIN_STABLE_CYCLES-1) ? stable_counter + 1'b1 : stable_counter;
  
  // 计数器寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter <= '0;
    end else begin
      stable_counter <= next_counter;
    end
  end
  
  // 计数器比较值流水线寄存器 - 切割关键路径
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      counter_compare <= '0;
    end else begin
      counter_compare <= stable_counter;
    end
  end
  
  // 稳定条件检测 - 第二级组合逻辑处理
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_condition <= 1'b0;
    end else begin
      stable_condition <= (counter_compare == MIN_STABLE_CYCLES-1);
    end
  end
  
  // 稳定条件流水线寄存器 - 进一步切割关键路径
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_condition_pipe <= 1'b0;
    end else begin
      stable_condition_pipe <= stable_condition;
    end
  end
  
  // 系统稳定输出寄存器
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      system_stable <= 1'b0;
    end else begin
      system_stable <= stable_condition_pipe;
    end
  end
  
endmodule