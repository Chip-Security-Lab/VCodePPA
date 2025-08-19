//SystemVerilog
//IEEE 1364-2005 Verilog
module can_error_counter(
  input wire clk, rst_n,
  input wire bit_error, stuff_error, form_error, crc_error, ack_error,
  input wire tx_success, rx_success,
  output reg [7:0] tx_err_count,
  output reg [7:0] rx_err_count,
  output reg bus_off
);
  // 错误信号分级处理
  wire format_protocol_error;
  wire data_error;
  wire any_error;
  
  // 分级错误检测
  assign data_error = bit_error | crc_error;
  assign format_protocol_error = stuff_error | form_error | ack_error;
  assign any_error = data_error | format_protocol_error;
  
  // TX错误计数器更新逻辑的优化常量
  localparam TX_ERR_INC = 8'd8;
  localparam MAX_ERR_COUNT = 8'd255;
  localparam BUS_OFF_THRESHOLD = 8'd250;

  // 计算下一个错误计数值的寄存器
  reg [7:0] next_tx_err_count;
  reg [7:0] next_rx_err_count;
  
  // TX错误计数器变量
  reg tx_count_dec;
  reg tx_count_inc;
  reg [7:0] tx_inc_value;
  
  // RX错误计数器变量
  reg rx_count_dec;
  reg rx_count_inc;
  
  // 总线状态信号
  reg next_bus_off;
  
  // TX错误计数逻辑分解
  always @(*) begin
    // 默认值设置
    tx_count_dec = 1'b0;
    tx_count_inc = 1'b0;
    tx_inc_value = TX_ERR_INC;
    
    // 成功传输判断
    if (tx_success) begin
      tx_count_dec = (|tx_err_count);
    end
    
    // 错误检测判断
    if (any_error) begin
      tx_count_inc = (tx_err_count < MAX_ERR_COUNT);
    end
  end
  
  // TX错误计数更新
  always @(*) begin
    if (tx_count_dec) begin
      next_tx_err_count = tx_err_count - 8'd1;
    end else if (tx_count_inc) begin
      next_tx_err_count = tx_err_count + tx_inc_value;
    end else begin
      next_tx_err_count = tx_err_count;
    end
  end
  
  // RX错误计数逻辑分解
  always @(*) begin
    // 默认值设置
    rx_count_dec = 1'b0;
    rx_count_inc = 1'b0;
    
    // 成功接收判断
    if (rx_success) begin
      rx_count_dec = (|rx_err_count);
    end
  end
  
  // RX错误计数更新
  always @(*) begin
    if (rx_count_dec) begin
      next_rx_err_count = rx_err_count - 8'd1;
    end else if (rx_count_inc) begin
      next_rx_err_count = rx_err_count + 8'd1;
    end else begin
      next_rx_err_count = rx_err_count;
    end
  end

  // 总线状态检测
  always @(*) begin
    if (next_tx_err_count >= BUS_OFF_THRESHOLD) begin
      next_bus_off = 1'b1;
    end else begin
      next_bus_off = 1'b0;
    end
  end

  // 错误计数器和总线状态更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_count <= 8'd0;
      rx_err_count <= 8'd0;
      bus_off <= 1'b0;
    end else begin
      tx_err_count <= next_tx_err_count;
      rx_err_count <= next_rx_err_count;
      bus_off <= next_bus_off;
    end
  end
endmodule