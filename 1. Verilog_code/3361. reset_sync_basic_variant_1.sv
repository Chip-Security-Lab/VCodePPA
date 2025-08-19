//SystemVerilog
// Module: reset_sync_basic
// 顶层模块 - 复位同步系统

module reset_sync_basic(
  input  wire clk,          // 系统时钟
  input  wire async_rst_n,  // 异步复位信号(低电平有效)
  output wire sync_rst_n    // 同步复位输出(低电平有效)
);
  // 内部连线声明
  wire rst_sync_stage_out;
  
  // 实例化第一级复位同步子模块
  rst_sync_stage1 u_rst_sync_stage1 (
    .clk           (clk),
    .async_rst_n   (async_rst_n),
    .stage1_rst_n  (rst_sync_stage_out)
  );
  
  // 实例化第二级复位同步子模块
  rst_sync_stage2 u_rst_sync_stage2 (
    .clk           (clk),
    .stage1_rst_n  (rst_sync_stage_out),
    .async_rst_n   (async_rst_n),
    .sync_rst_n    (sync_rst_n)
  );

endmodule

// 第一级复位同步子模块
module rst_sync_stage1 (
  input  wire clk,          // 系统时钟
  input  wire async_rst_n,  // 异步复位信号(低电平有效)
  output wire stage1_rst_n  // 第一级同步输出
);
  // 第一级同步寄存器
  (* ASYNC_REG = "TRUE" *)  // 综合指令：指示异步寄存器，优化布局
  reg stage1_reg;
  
  // 第一级复位同步逻辑
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      // 异步复位路径
      stage1_reg <= 1'b0;
    end else begin
      // 同步数据路径 - 捕获恒定的1值
      stage1_reg <= 1'b1;
    end
  end
  
  // 输出连接
  assign stage1_rst_n = stage1_reg;
  
endmodule

// 第二级复位同步子模块
module rst_sync_stage2 (
  input  wire clk,          // 系统时钟
  input  wire stage1_rst_n, // 第一级同步输入
  input  wire async_rst_n,  // 异步复位信号(用于异步复位路径)
  output wire sync_rst_n    // 最终同步复位输出
);
  // 第二级同步寄存器 
  (* ASYNC_REG = "TRUE" *)  // 综合指令：指示异步寄存器，优化布局
  reg stage2_reg;
  
  // 第二级复位同步逻辑
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      // 异步复位路径
      stage2_reg <= 1'b0;
    end else begin
      // 同步数据路径 - 传播第一级结果
      stage2_reg <= stage1_rst_n;
    end
  end
  
  // 输出连接
  assign sync_rst_n = stage2_reg;
  
endmodule