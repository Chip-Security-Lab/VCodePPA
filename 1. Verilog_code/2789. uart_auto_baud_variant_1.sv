//SystemVerilog
module uart_auto_baud (
  input  wire       clk,
  input  wire       reset_n,
  input  wire       rx,
  output reg  [7:0] rx_data,
  output reg        rx_valid,
  output reg  [15:0] detected_baud
);
  // 常量定义 - 更清晰地分组
  // 自动波特率检测状态
  localparam [1:0] AB_IDLE    = 2'b00;
  localparam [1:0] AB_START   = 2'b01;
  localparam [1:0] AB_MEASURE = 2'b10;
  localparam [1:0] AB_LOCK    = 2'b11;
  
  // UART接收状态
  localparam [1:0] RX_IDLE    = 2'b00;
  localparam [1:0] RX_START   = 2'b01;
  localparam [1:0] RX_DATA    = 2'b10;
  localparam [1:0] RX_STOP    = 2'b11;
  
  // 时钟和系统参数
  localparam CLOCK_FREQ = 50_000_000; // 系统时钟频率 (50MHz)
  
  // 波特率检测模块信号
  reg [1:0]  ab_state_r;      // 自动波特率状态寄存器
  reg [1:0]  ab_state_next;   // 状态机下一状态
  reg        rx_prev_r;       // 前一个RX值用于边沿检测
  reg        rx_sync_r;       // 同步RX输入
  reg        rx_sync2_r;      // 二级同步器
  reg [15:0] clk_counter_r;   // 时钟计数器
  reg [15:0] clk_counter_next;
  reg [15:0] baud_period_r;   // 测量的波特周期
  reg [15:0] baud_period_next;
  reg [15:0] detected_baud_next;
  wire       rx_edge;         // RX边沿检测信号
  
  // UART接收模块信号
  reg [1:0]  rx_state_r;      // 接收状态机状态
  reg [1:0]  rx_state_next;
  reg [15:0] bit_timer_r;     // 比特定时计数器
  reg [15:0] bit_timer_next;
  reg [2:0]  bit_counter_r;   // 比特位置计数器
  reg [2:0]  bit_counter_next;
  reg [7:0]  rx_shift_r;      // 接收移位寄存器
  reg [7:0]  rx_shift_next;
  reg [7:0]  rx_data_next;
  reg        rx_valid_next;
  
  // 边沿检测逻辑
  assign rx_edge = rx_prev_r != rx_sync_r;
  
  // 输入同步器 - 防止亚稳态
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_sync_r <= 1'b1;
      rx_sync2_r <= 1'b1;
      rx_prev_r <= 1'b1;
    end else begin
      rx_sync2_r <= rx;       // 第一级同步
      rx_sync_r <= rx_sync2_r; // 第二级同步
      rx_prev_r <= rx_sync_r;  // 保存前一个值用于边沿检测
    end
  end
  
  // 自动波特率检测状态机 - 组合逻辑
  always @(*) begin
    // 默认保持当前值
    ab_state_next = ab_state_r;
    
    case (ab_state_r)
      AB_IDLE: begin
        if (rx_prev_r == 1'b1 && rx_sync_r == 1'b0) begin // 下降沿(起始位开始)
          ab_state_next = AB_START;
        end
      end
      
      AB_START: begin
        if (rx_prev_r == 1'b0 && rx_sync_r == 1'b1) begin // 上升沿(起始位到第一个数据位)
          ab_state_next = AB_MEASURE;
        end
      end
      
      AB_MEASURE: begin
        if (rx_edge && clk_counter_r >= baud_period_r/2) begin
          // 基于多个边沿确认测量
          ab_state_next = AB_LOCK;
        end
      end
      
      AB_LOCK: begin
        // 自动波特率锁定，状态不变
      end
    endcase
  end
  
  // 自动波特率检测计数器管理
  always @(*) begin
    // 默认保持当前值
    clk_counter_next = clk_counter_r;
    
    case (ab_state_r)
      AB_IDLE: begin
        clk_counter_next = 16'd0;
      end
      
      AB_START: begin
        clk_counter_next = clk_counter_r + 1'b1;
        if (rx_prev_r == 1'b0 && rx_sync_r == 1'b1) begin // 上升沿
          clk_counter_next = 16'd0;
        end
      end
      
      AB_MEASURE: begin
        clk_counter_next = clk_counter_r + 1'b1;
        if (rx_edge) begin
          clk_counter_next = 16'd0;
        end
      end
      
      AB_LOCK: begin
        // 锁定状态下计数器保持不变
      end
    endcase
  end
  
  // 自动波特率参数计算
  always @(*) begin
    // 默认保持当前值
    baud_period_next = baud_period_r;
    detected_baud_next = detected_baud;
    
    case (ab_state_r)
      AB_IDLE: begin
        // 空闲状态不改变波特率参数
      end
      
      AB_START: begin
        if (rx_prev_r == 1'b0 && rx_sync_r == 1'b1) begin // 上升沿
          baud_period_next = clk_counter_r;
        end
      end
      
      AB_MEASURE: begin
        if (rx_edge && clk_counter_r >= baud_period_r/2) begin
          detected_baud_next = (CLOCK_FREQ / baud_period_r);
        end
      end
      
      AB_LOCK: begin
        // 锁定状态下波特率参数保持不变
      end
    endcase
  end
  
  // UART接收状态机 - 组合逻辑
  always @(*) begin
    // 默认保持当前值
    rx_state_next = rx_state_r;
    
    if (ab_state_r == AB_LOCK) begin
      case (rx_state_r)
        RX_IDLE: begin
          if (rx_sync_r == 1'b0) begin // 起始位
            rx_state_next = RX_START;
          end
        end
        
        RX_START: begin
          if (bit_timer_r >= baud_period_r/2) begin
            rx_state_next = RX_DATA;
          end
        end
        
        RX_DATA: begin
          if (bit_timer_r >= baud_period_r && bit_counter_r == 3'd7) begin
            rx_state_next = RX_STOP;
          end
        end
        
        RX_STOP: begin
          if (bit_timer_r >= baud_period_r) begin
            rx_state_next = RX_IDLE;
          end
        end
      endcase
    end
  end
  
  // UART接收定时控制
  always @(*) begin
    // 默认保持当前值
    bit_timer_next = bit_timer_r;
    bit_counter_next = bit_counter_r;
    
    if (ab_state_r == AB_LOCK) begin
      case (rx_state_r)
        RX_IDLE: begin
          bit_timer_next = 16'd0;
        end
        
        RX_START: begin
          bit_timer_next = bit_timer_r + 1'b1;
          if (bit_timer_r >= baud_period_r/2) begin
            bit_timer_next = 16'd0;
            bit_counter_next = 3'd0;
          end
        end
        
        RX_DATA: begin
          bit_timer_next = bit_timer_r + 1'b1;
          if (bit_timer_r >= baud_period_r) begin
            bit_timer_next = 16'd0;
            if (bit_counter_r < 3'd7) begin
              bit_counter_next = bit_counter_r + 1'b1;
            end
          end
        end
        
        RX_STOP: begin
          bit_timer_next = bit_timer_r + 1'b1;
          if (bit_timer_r >= baud_period_r) begin
            bit_timer_next = 16'd0;
          end
        end
      endcase
    end
  end
  
  // UART接收数据处理
  always @(*) begin
    // 默认保持当前值
    rx_shift_next = rx_shift_r;
    rx_data_next = rx_data;
    rx_valid_next = 1'b0; // 默认无效
    
    if (ab_state_r == AB_LOCK) begin
      case (rx_state_r)
        RX_DATA: begin
          if (bit_timer_r >= baud_period_r) begin
            rx_shift_next = {rx_sync_r, rx_shift_r[7:1]};
          end
        end
        
        RX_STOP: begin
          if (bit_timer_r >= baud_period_r && rx_sync_r == 1'b1) begin // 有效停止位
            rx_valid_next = 1'b1;
            rx_data_next = rx_shift_r;
          end
        end
        
        default: begin
          // 其他状态不处理数据
        end
      endcase
    end
  end
  
  // 自动波特率检测寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ab_state_r <= AB_IDLE;
      clk_counter_r <= 16'd0;
      baud_period_r <= 16'd0;
      detected_baud <= 16'd0;
    end else begin
      ab_state_r <= ab_state_next;
      clk_counter_r <= clk_counter_next;
      baud_period_r <= baud_period_next;
      detected_baud <= detected_baud_next;
    end
  end
  
  // UART接收器寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state_r <= RX_IDLE;
      bit_timer_r <= 16'd0;
      bit_counter_r <= 3'd0;
      rx_shift_r <= 8'd0;
      rx_data <= 8'd0;
      rx_valid <= 1'b0;
    end else begin
      rx_state_r <= rx_state_next;
      bit_timer_r <= bit_timer_next;
      bit_counter_r <= bit_counter_next;
      rx_shift_r <= rx_shift_next;
      rx_data <= rx_data_next;
      rx_valid <= rx_valid_next;
    end
  end
  
endmodule