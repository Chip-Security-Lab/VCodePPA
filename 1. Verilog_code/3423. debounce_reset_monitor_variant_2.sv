//SystemVerilog
module debounce_reset_monitor #(
  parameter DEBOUNCE_CYCLES = 8
) (
  input  wire clk,
  input  wire reset_in,
  output reg  reset_out
);
  // 定义阶段信号和计数器
  localparam CNT_WIDTH = $clog2(DEBOUNCE_CYCLES);
  
  // 输入同步化阶段
  reg reset_in_meta;
  reg reset_in_sync;
  
  // 去抖动计数阶段
  reg [CNT_WIDTH-1:0] debounce_counter;
  reg count_active;
  reg count_done;
  
  // 使用直接比较操作替代借位减法器逻辑
  wire counter_at_target = (debounce_counter == DEBOUNCE_CYCLES - 1);
  
  // 输入同步化 - 减少亚稳态风险
  always @(posedge clk) begin
    reset_in_meta <= reset_in;
    reset_in_sync <= reset_in_meta;
  end
  
  // 计数器控制逻辑 - 优化实现
  always @(posedge clk) begin
    // 检测输入变化
    if (reset_in_sync != reset_in_meta) begin
      // 重置计数器和状态
      debounce_counter <= {CNT_WIDTH{1'b0}};
      count_active <= 1'b1;
      count_done <= 1'b0;
    end
    // 使用优化的比较方式
    else if (count_active) begin
      if (counter_at_target) begin
        // 计数完成
        count_active <= 1'b0;
        count_done <= 1'b1;
        debounce_counter <= debounce_counter; // 保持计数值
      end
      else begin
        // 继续计数
        debounce_counter <= debounce_counter + 1'b1;
        count_done <= 1'b0;
      end
    end
    else begin
      count_done <= 1'b0;
    end
  end
  
  // 输出寄存阶段 - 最终结果更新
  always @(posedge clk) begin
    if (count_done) begin
      reset_out <= reset_in_sync;
    end
  end
  
endmodule