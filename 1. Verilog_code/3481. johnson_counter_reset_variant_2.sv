//SystemVerilog
module johnson_counter_reset #(parameter WIDTH = 8)(
  input clk, rst, enable,
  output reg [WIDTH-1:0] johnson_count,
  output reg valid_out
);
  // 流水线寄存器 - 优化位宽和初始值表示
  reg [WIDTH-1:0] johnson_stage1, johnson_stage2;
  reg enable_pipe [1:0];
  reg valid_pipe [1:0];
  
  // 初始值常量 - 避免重复计算
  localparam [WIDTH-1:0] INIT_VALUE = {{WIDTH-1{1'b0}}, 1'b1};
  
  // 第一级流水线 - 计算新值 (优化逻辑结构)
  always @(posedge clk) begin
    if (rst) begin
      johnson_stage1 <= INIT_VALUE;
      enable_pipe[0] <= 1'b0;
      valid_pipe[0] <= 1'b0;
    end else begin
      enable_pipe[0] <= enable;
      // 条件移动外部以减少逻辑深度
      valid_pipe[0] <= enable ? 1'b1 : 1'b0;
      if (enable) begin
        // 优化位操作，使用位级表达式
        johnson_stage1 <= {johnson_count[WIDTH-2:0], ~johnson_count[WIDTH-1]};
      end
    end
  end
  
  // 第二级流水线 - 数据传递 (简化逻辑)
  always @(posedge clk) begin
    if (rst) begin
      johnson_stage2 <= INIT_VALUE;
      enable_pipe[1] <= 1'b0;
      valid_pipe[1] <= 1'b0;
    end else begin
      johnson_stage2 <= johnson_stage1;
      enable_pipe[1] <= enable_pipe[0];
      valid_pipe[1] <= valid_pipe[0];
    end
  end
  
  // 输出级 - 更新最终计数结果 (无条件更新减少多路选择器)
  always @(posedge clk) begin
    if (rst) begin
      johnson_count <= INIT_VALUE;
      valid_out <= 1'b0;
    end else begin
      johnson_count <= johnson_stage2;
      valid_out <= valid_pipe[1];
    end
  end
endmodule