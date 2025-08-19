//SystemVerilog
module uart_memory_mapped #(parameter ADDR_WIDTH = 4) (
  input wire clk, reset_n,
  // Bus interface
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [7:0] wdata,
  input wire write_en, read_en,
  output reg [7:0] rdata,
  // UART signals
  input wire rx_in,
  output wire tx_out
);
  // Register map - 使用独热编码以降低比较器深度
  localparam REG_TX_DATA  = 0;    // Write: TX data
  localparam REG_RX_DATA  = 1;    // Read: RX data
  localparam REG_STATUS   = 2;    // Read: Status register
  localparam REG_CONTROL  = 3;    // R/W: Control register
  localparam REG_BAUD_DIV = 4;    // R/W: Baud rate divider
  
  // 独热编码地址解码器
  wire [4:0] addr_dec;
  assign addr_dec[REG_TX_DATA]  = (addr == 4'h0);
  assign addr_dec[REG_RX_DATA]  = (addr == 4'h1);
  assign addr_dec[REG_STATUS]   = (addr == 4'h2);
  assign addr_dec[REG_CONTROL]  = (addr == 4'h3);
  assign addr_dec[REG_BAUD_DIV] = (addr == 4'h4);
  
  // Internal registers
  reg [7:0] tx_data_reg;
  reg [7:0] rx_data_reg;
  reg [7:0] status_reg;  // [7:rx_ready, 6:tx_busy, 5:rx_overrun, 4:frame_err, 3-0:reserved]
  reg [7:0] control_reg; // [7:rx_int_en, 6:tx_int_en, 5:rx_en, 4:tx_en, 3-0:reserved]
  reg [7:0] baud_div_reg;
  
  // UART control signals
  reg tx_start;
  wire tx_busy, rx_ready;
  wire [7:0] rx_data;
  wire frame_error;
  wire tx_done;
  
  // 提取控制位以提高可读性并减少逻辑深度
  wire tx_enable = control_reg[4];
  wire rx_enable = control_reg[5];
  
  // Bus interface logic - 优化时序路径
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      tx_data_reg <= 8'h0;
      control_reg <= 8'h30; // Enable TX and RX by default
      baud_div_reg <= 8'd16; // Default baud divider
      tx_start <= 1'b0;
      status_reg <= 8'h0;
      rx_data_reg <= 8'h0;
    end else begin
      // 默认值设置
      tx_start <= 1'b0; // Auto-clear tx_start
      
      // 状态寄存器更新 - 分离更新逻辑减少关键路径
      status_reg[7] <= rx_ready;
      status_reg[6] <= tx_busy;
      status_reg[4] <= frame_error;
      
      // RX数据处理 - 优先级处理
      if (rx_ready) begin
        rx_data_reg <= rx_data;
        // 仅在RX就绪标志已经设置时设置溢出标志
        if (status_reg[7]) 
          status_reg[5] <= 1'b1; // Set overrun flag
      end
      
      // 清除状态位 - 优先级高于写操作
      if (read_en && addr_dec[REG_STATUS]) begin
        status_reg[5] <= 1'b0; // Clear overrun flag on read
      end
      
      // 写操作处理 - 使用独热编码减少比较器深度
      if (write_en) begin
        if (addr_dec[REG_TX_DATA]) begin
          tx_data_reg <= wdata;
          tx_start <= tx_enable; // 仅当TX启用时自动启动
        end else if (addr_dec[REG_CONTROL]) begin
          control_reg <= wdata;
        end else if (addr_dec[REG_BAUD_DIV]) begin
          baud_div_reg <= wdata;
        end
      end
    end
  end
  
  // Read operations - 优化为并行多路复用器结构
  always @(*) begin
    rdata = 8'h00; // 默认值
    
    if (read_en) begin
      if (addr_dec[REG_RX_DATA])
        rdata = rx_data_reg;
      else if (addr_dec[REG_STATUS])
        rdata = status_reg;
      else if (addr_dec[REG_CONTROL])
        rdata = control_reg;
      else if (addr_dec[REG_BAUD_DIV])
        rdata = baud_div_reg;
    end
  end
  
  // TX模块简化实现 - 改进信号依赖关系
  reg tx_busy_r;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      tx_busy_r <= 1'b0;
    else if (tx_start)
      tx_busy_r <= 1'b1;
    else if (tx_done)
      tx_busy_r <= 1'b0;
  end
  
  assign tx_out = 1'b1;  // 空闲状态为高电平
  assign tx_busy = tx_busy_r;
  assign tx_done = tx_busy_r & ~tx_start; // 当忙状态结束时
  
  // RX桩实现的改进
  reg rx_ready_r;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n)
      rx_ready_r <= 1'b0;
    else
      rx_ready_r <= rx_in & rx_enable; // 仅当RX启用时才接收
  end
  
  assign rx_ready = rx_ready_r;
  assign rx_data = 8'hAA; // 测试数据
  assign frame_error = 1'b0; // 无错误
  
endmodule