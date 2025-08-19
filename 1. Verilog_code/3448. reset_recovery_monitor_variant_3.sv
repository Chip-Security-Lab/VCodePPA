//SystemVerilog
module reset_recovery_monitor #(
  parameter MIN_STABLE_CYCLES = 16
) (
  input wire clk,
  input wire reset_n,
  output reg system_stable
);
  localparam COUNTER_WIDTH = $clog2(MIN_STABLE_CYCLES);
  reg [COUNTER_WIDTH-1:0] stable_counter;
  wire [COUNTER_WIDTH-1:0] target_value;
  wire counter_reached;
  
  // 使用二进制补码算法实现目标值的比较
  // 目标值为MIN_STABLE_CYCLES-1
  assign target_value = MIN_STABLE_CYCLES - 1;
  
  // 使用二进制补码比较算法检查是否达到目标值
  // 两个数相减为零表示相等
  assign counter_reached = ((stable_counter ^ target_value) == {COUNTER_WIDTH{1'b0}});
  
  // 寄存器重定时：将组合逻辑后的寄存器移到组合逻辑前
  reg counter_reached_reg;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      stable_counter <= {COUNTER_WIDTH{1'b0}};
      counter_reached_reg <= 1'b0;
      system_stable <= 1'b0;
    end else begin
      if (stable_counter < target_value)
        stable_counter <= stable_counter + 1'b1;
      
      // 寄存器前移，减少关键路径
      counter_reached_reg <= counter_reached;
      
      // 输出寄存器直接使用预计算值
      system_stable <= counter_reached_reg;
    end
  end
endmodule