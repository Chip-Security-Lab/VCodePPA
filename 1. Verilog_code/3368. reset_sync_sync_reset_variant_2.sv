//SystemVerilog
//============================================================================
// Top-level module: reset_sync_sync_reset
//============================================================================
module reset_sync_sync_reset #(
  parameter SYNC_STAGES = 2,       // 参数化设计，默认2级同步
  parameter INIT_VALUE  = 1'b0     // 初始状态值，默认为0
)(
  input  wire clk,                 // 系统时钟
  input  wire rst_n,               // 异步复位信号，低有效
  output wire sync_rst_n           // 同步复位信号输出 (改名为sync_rst_n更符合低电平有效的命名)
);

  // 内部信号定义 - 清晰的流水线信号命名
  reg  [SYNC_STAGES-1:0] sync_chain;   // 复位同步链寄存器 (流水线)
  
  // 复位同步流水线实现
  // 注: 使用非阻塞赋值确保正确的仿真行为和综合结果
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sync_chain <= {SYNC_STAGES{INIT_VALUE}}; // 复位时所有同步级清零
    end else begin
      sync_chain <= {sync_chain[SYNC_STAGES-2:0], 1'b1}; // 移位操作形成流水线
    end
  end
  
  // 输出赋值 - 取同步链的最后一级作为输出
  assign sync_rst_n = sync_chain[SYNC_STAGES-1];

endmodule