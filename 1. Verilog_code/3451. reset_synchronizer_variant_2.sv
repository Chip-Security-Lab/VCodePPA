//SystemVerilog
// 顶层模块
module reset_synchronizer (
  input  wire clk,
  input  wire async_reset_n,
  output wire sync_reset_n
);
  
  // 内部连线
  wire meta_stage_out;
  
  // 实例化优化后的元稳态捕获子模块
  metastability_catcher meta_stage (
    .clk           (clk),
    .async_reset_n (async_reset_n),
    .meta_out      (meta_stage_out)
  );
  
  // 实例化优化后的输出同步子模块
  sync_output_stage sync_stage (
    .clk           (clk),
    .async_reset_n (async_reset_n),
    .meta_in       (meta_stage_out),
    .sync_reset_n  (sync_reset_n)
  );
  
endmodule

// 优化后的元稳态捕获子模块
module metastability_catcher (
  input  wire clk,
  input  wire async_reset_n,
  output reg  meta_out
);
  
  reg async_reset_n_sampled;
  
  // 首先对异步复位信号进行采样，减少输入到第一级寄存器的路径延迟
  always @(posedge clk) begin
    async_reset_n_sampled <= async_reset_n;
  end
  
  // 基于采样后的复位信号进行后续逻辑
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      // 保持原有的异步复位行为
      meta_out <= 1'b0;
    end else begin
      // 使用采样后的复位信号进行条件判断
      if (async_reset_n_sampled) begin
        meta_out <= 1'b1;
      end else begin
        meta_out <= 1'b0;
      end
    end
  end
  
endmodule

// 优化后的输出同步子模块
module sync_output_stage (
  input  wire clk,
  input  wire async_reset_n,
  input  wire meta_in,
  output reg  sync_reset_n
);
  
  reg meta_in_sampled;
  
  // 对输入信号进行前向寄存登记
  always @(posedge clk) begin
    meta_in_sampled <= meta_in;
  end
  
  // 保持异步复位功能不变
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      sync_reset_n <= 1'b0;
    end else begin
      // 使用采样后的信号
      sync_reset_n <= meta_in_sampled;
    end
  end
  
endmodule