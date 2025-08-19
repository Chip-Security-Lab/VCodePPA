//SystemVerilog
module dual_reset_counter #(
  parameter WIDTH = 8
)(
  input                  clk,         // 时钟输入
  input                  sync_rst,    // 同步复位信号
  input                  async_rst_n, // 异步复位信号（低电平有效）
  input                  enable,      // 使能信号
  output reg [WIDTH-1:0] count        // 计数器输出
);

  // 分解高扇出信号，为同步复位和异步复位创建缓冲寄存器
  reg sync_rst_buf1, sync_rst_buf2;
  reg async_rst_n_buf1, async_rst_n_buf2;
  reg enable_buf;
  
  // 异步复位信号缓冲 - 分散负载
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      async_rst_n_buf1 <= 1'b0;
      async_rst_n_buf2 <= 1'b0;
    end else begin
      async_rst_n_buf1 <= 1'b1;
      async_rst_n_buf2 <= 1'b1;
    end
  end
  
  // 同步复位信号缓冲 - 分散负载
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      sync_rst_buf1 <= 1'b0;
      sync_rst_buf2 <= 1'b0;
    end else begin
      sync_rst_buf1 <= sync_rst;
      sync_rst_buf2 <= sync_rst;
    end
  end
  
  // 使能信号缓冲
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      enable_buf <= 1'b0;
    end else begin
      enable_buf <= enable;
    end
  end
  
  // 优化后的复位条件逻辑，使用缓冲后的信号
  wire reset_condition_upper = !async_rst_n_buf1 | sync_rst_buf1;
  wire reset_condition_lower = !async_rst_n_buf2 | sync_rst_buf2;
  
  // 拆分计数器为上半部分和下半部分以降低关键路径的负载
  reg [WIDTH/2-1:0] count_upper;
  reg [WIDTH/2-1:0] count_lower;
  wire [WIDTH-1:0] next_count = {count_upper, count_lower} + 1'b1;
  
  // 计数器使能逻辑，使用缓冲后的信号降低扇出
  wire count_enable = enable_buf & !sync_rst_buf1 & async_rst_n_buf1;
  
  // 上半部分计数器逻辑
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      count_upper <= {(WIDTH/2){1'b0}};
    end else begin
      if (count_enable)
        count_upper <= next_count[WIDTH-1:WIDTH/2];
      else if (sync_rst_buf1)
        count_upper <= {(WIDTH/2){1'b0}};
    end
  end
  
  // 下半部分计数器逻辑
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      count_lower <= {(WIDTH/2){1'b0}};
    end else begin
      if (count_enable)
        count_lower <= next_count[WIDTH/2-1:0];
      else if (sync_rst_buf2)
        count_lower <= {(WIDTH/2){1'b0}};
    end
  end
  
  // 组合最终输出
  always @(posedge clk or negedge async_rst_n) begin
    if (!async_rst_n) begin
      count <= {WIDTH{1'b0}};
    end else begin
      count <= {count_upper, count_lower};
    end
  end
  
endmodule