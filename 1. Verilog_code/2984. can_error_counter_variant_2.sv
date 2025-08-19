//SystemVerilog
module can_error_counter(
  input  wire        clk,           // 系统时钟
  input  wire        rst_n,         // 低电平有效复位
  input  wire        bit_error,     // 比特错误信号
  input  wire        stuff_error,   // 填充错误信号
  input  wire        form_error,    // 格式错误信号
  input  wire        crc_error,     // CRC错误信号
  input  wire        ack_error,     // 确认错误信号
  input  wire        tx_success,    // 发送成功信号
  input  wire        rx_success,    // 接收成功信号
  output reg  [7:0]  tx_err_count,  // 发送错误计数
  output reg  [7:0]  rx_err_count,  // 接收错误计数
  output reg         bus_off        // 总线关闭状态
);

  // 流水线寄存器 - 第一级
  reg bit_error_r, stuff_error_r, form_error_r, crc_error_r, ack_error_r;
  reg tx_success_r, rx_success_r;
  
  // 错误检测阶段 - 合并错误信号
  reg error_detected;
  
  // 流水线寄存器 - 第二级
  reg error_detected_r;
  reg [7:0] tx_err_count_r;
  reg [7:0] rx_err_count_r;
  
  // 错误计数阶段 - 计算下一个错误计数值
  reg [7:0] next_tx_err_count;
  reg [7:0] next_rx_err_count;
  reg       next_bus_off;
  
  // 第一级流水线寄存器 - 输入信号同步
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_error_r   <= 1'b0;
      stuff_error_r <= 1'b0;
      form_error_r  <= 1'b0;
      crc_error_r   <= 1'b0;
      ack_error_r   <= 1'b0;
      tx_success_r  <= 1'b0;
      rx_success_r  <= 1'b0;
    end else begin
      bit_error_r   <= bit_error;
      stuff_error_r <= stuff_error;
      form_error_r  <= form_error;
      crc_error_r   <= crc_error;
      ack_error_r   <= ack_error;
      tx_success_r  <= tx_success;
      rx_success_r  <= rx_success;
    end
  end
  
  // 错误检测流水线级 - 组合所有错误类型（减少组合逻辑深度）
  always @(*) begin
    error_detected = bit_error_r || stuff_error_r || form_error_r || crc_error_r || ack_error_r;
  end
  
  // 第二级流水线寄存器 - 错误检测和计数值同步
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_detected_r <= 1'b0;
      tx_err_count_r   <= 8'd0;
      rx_err_count_r   <= 8'd0;
    end else begin
      error_detected_r <= error_detected;
      tx_err_count_r   <= tx_err_count;
      rx_err_count_r   <= rx_err_count;
    end
  end
  
  // 发送错误计数流水线级 - 计算下一状态（错误和成功信号已经流水线化）
  always @(*) begin
    if (tx_success_r) begin
      next_tx_err_count = (tx_err_count_r > 8'd0) ? (tx_err_count_r - 8'd1) : 8'd0;
    end else if (error_detected_r) begin
      next_tx_err_count = (tx_err_count_r < 8'd255) ? (tx_err_count_r + 8'd8) : 8'd255;
    end else begin
      next_tx_err_count = tx_err_count_r;
    end
  end
  
  // 接收错误计数流水线级 - 计算下一状态
  always @(*) begin
    if (rx_success_r) begin
      next_rx_err_count = (rx_err_count_r > 8'd0) ? (rx_err_count_r - 8'd1) : 8'd0;
    end else begin
      next_rx_err_count = rx_err_count_r;
    end
  end
  
  // 总线状态控制流水线级 - 使用流水线寄存器中的值
  always @(*) begin
    next_bus_off = (next_tx_err_count >= 8'd255);
  end
  
  // 同步更新所有状态寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // 异步复位所有计数器和状态
      tx_err_count <= 8'd0;
      rx_err_count <= 8'd0;
      bus_off      <= 1'b0;
    end else begin
      // 同步更新所有状态
      tx_err_count <= next_tx_err_count;
      rx_err_count <= next_rx_err_count;
      bus_off      <= next_bus_off;
    end
  end

endmodule