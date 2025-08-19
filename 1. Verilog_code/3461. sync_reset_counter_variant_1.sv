//SystemVerilog
module sync_reset_counter #(
  parameter WIDTH = 8
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire             enable,
  output reg  [WIDTH-1:0] count
);

  // 优化的流水线寄存器
  reg enable_pipe [1:0];
  reg [WIDTH-1:0] count_pipe [1:0];
  
  // 统一的流水线逻辑 - 使用参数化索引减少代码重复
  always @(posedge clk) begin
    if (!rst_n) begin
      // 统一复位逻辑，提高性能
      {enable_pipe[0], enable_pipe[1]} <= 2'b0;
      {count_pipe[0], count_pipe[1]} <= {2{{WIDTH{1'b0}}}};
      count <= {WIDTH{1'b0}};
    end
    else begin
      // 第一级流水线 - 寄存输入
      enable_pipe[0] <= enable;
      count_pipe[0] <= count;
      
      // 第二级流水线 - 准备增量
      enable_pipe[1] <= enable_pipe[0];
      count_pipe[1] <= count_pipe[0];
      
      // 最终流水线阶段 - 条件更新输出
      if (enable_pipe[1]) begin
        count <= count_pipe[1] + 1'b1;
      end
    end
  end
  
endmodule