//SystemVerilog
module reset_sync_pass(
  input  wire clk,      // 时钟输入
  input  wire rst_n,    // 低电平有效复位
  input  wire data_in,  // 数据输入
  output reg  data_out  // 同步后的数据输出
);
  // 使用显式初始值以优化某些综合工具的初始化行为
  (* dont_touch = "true" *) reg stg = 1'b0;
  
  // 为高扇出信号stg增加缓冲寄存器
  (* dont_touch = "true" *) reg stg_buf1 = 1'b0;
  (* dont_touch = "true" *) reg stg_buf2 = 1'b0;
  
  // 单个always块处理stg信号和第一个缓冲寄存器
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // 异步复位行为
      stg <= 1'b0;
      stg_buf1 <= 1'b0;
    end else begin
      // 正常操作 - 双级同步器首级实现
      stg <= data_in;
      stg_buf1 <= stg;
    end
  end
  
  // 第二个always块处理第二个缓冲寄存器和输出
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      // 异步复位行为
      stg_buf2 <= 1'b0;
      data_out <= 1'b0;
    end else begin
      // 从第一个缓冲寄存器加载数据
      stg_buf2 <= stg_buf1;
      data_out <= stg_buf2;
    end
  end
endmodule