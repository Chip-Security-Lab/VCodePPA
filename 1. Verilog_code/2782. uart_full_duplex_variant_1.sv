//SystemVerilog
module uart_full_duplex (
  input wire clk, rst_n,
  input wire rx_in,
  output wire tx_out,
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg tx_busy,
  output reg [7:0] rx_data,
  output reg rx_ready,
  output reg rx_error
);
  // TX state machine
  localparam TX_IDLE = 2'b00, TX_START = 2'b01, TX_DATA = 2'b10, TX_STOP = 2'b11;
  reg [1:0] tx_state, tx_next_state;
  reg [2:0] tx_bit_pos, tx_next_bit_pos;
  reg [7:0] tx_shift_reg, tx_next_shift_reg;
  reg tx_out_reg, tx_next_out_reg;
  reg tx_next_busy;
  
  // RX state machine
  localparam RX_IDLE = 2'b00, RX_START = 2'b01, RX_DATA = 2'b10, RX_STOP = 2'b11;
  reg [1:0] rx_state, rx_next_state;
  reg [2:0] rx_bit_pos, rx_next_bit_pos;
  reg [7:0] rx_shift_reg, rx_next_shift_reg;
  reg rx_next_ready, rx_next_error;
  reg [7:0] rx_next_data;
  
  // Baud rate control - 预计算波特率计数器
  localparam TX_BAUD_MAX = 8'd104; // For 9600 baud @ 1MHz
  localparam RX_BAUD_MAX = 8'd26;  // 4x oversampling
  
  reg [7:0] baud_count_tx, baud_count_rx;
  wire baud_tick_tx, baud_tick_rx;
  
  assign baud_tick_tx = (baud_count_tx == TX_BAUD_MAX);
  assign baud_tick_rx = (baud_count_rx == RX_BAUD_MAX);
  assign tx_out = tx_out_reg;
  
  // 流水线寄存器 - TX部分
  reg [1:0] tx_state_pipe;
  reg [2:0] tx_bit_pos_pipe;
  reg tx_busy_pipe;
  reg baud_tick_tx_pipe;
  
  // 流水线寄存器 - RX部分
  reg [1:0] rx_state_pipe;
  reg [2:0] rx_bit_pos_pipe;
  reg rx_in_pipe;
  reg baud_tick_rx_pipe;
  
  // TX 波特率计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_count_tx <= 0;
    end else begin
      baud_count_tx <= (baud_count_tx == TX_BAUD_MAX) ? 8'd0 : baud_count_tx + 1'b1;
    end
  end
  
  // RX 波特率计数器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      baud_count_rx <= 0;
    end else begin
      baud_count_rx <= (baud_count_rx == RX_BAUD_MAX) ? 8'd0 : baud_count_rx + 1'b1;
    end
  end
  
  // 流水线寄存器更新 - 第一级
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state_pipe <= TX_IDLE;
      tx_bit_pos_pipe <= 3'd0;
      tx_busy_pipe <= 1'b0;
      baud_tick_tx_pipe <= 1'b0;
      
      rx_state_pipe <= RX_IDLE;
      rx_bit_pos_pipe <= 3'd0;
      rx_in_pipe <= 1'b1;
      baud_tick_rx_pipe <= 1'b0;
    end else begin
      tx_state_pipe <= tx_state;
      tx_bit_pos_pipe <= tx_bit_pos;
      tx_busy_pipe <= tx_busy;
      baud_tick_tx_pipe <= baud_tick_tx;
      
      rx_state_pipe <= rx_state;
      rx_bit_pos_pipe <= rx_bit_pos;
      rx_in_pipe <= rx_in;
      baud_tick_rx_pipe <= baud_tick_rx;
    end
  end
  
  // TX 组合逻辑第一阶段 - 状态转换判断
  reg [1:0] tx_interim_state;
  reg tx_interim_busy;
  reg [2:0] tx_interim_bit_pos;
  
  always @(*) begin
    // 默认保持当前状态
    tx_interim_state = tx_state_pipe;
    tx_interim_busy = tx_busy_pipe;
    tx_interim_bit_pos = tx_bit_pos_pipe;
    
    if (baud_tick_tx_pipe) begin
      case (tx_state_pipe)
        TX_IDLE: begin
          if (tx_start) begin
            tx_interim_state = TX_START;
            tx_interim_busy = 1'b1;
          end
        end
        
        TX_START: begin
          tx_interim_state = TX_DATA;
          tx_interim_bit_pos = 3'd0;
        end
        
        TX_DATA: begin
          if (tx_bit_pos_pipe == 3'd7) begin
            tx_interim_state = TX_STOP;
          end else begin
            tx_interim_bit_pos = tx_bit_pos_pipe + 1'b1;
          end
        end
        
        TX_STOP: begin
          tx_interim_state = TX_IDLE;
          tx_interim_busy = 1'b0;
        end
        
        default: tx_interim_state = TX_IDLE;
      endcase
    end
  end
  
  // TX 组合逻辑第二阶段 - 数据操作
  always @(*) begin
    // 默认值
    tx_next_state = tx_interim_state;
    tx_next_bit_pos = tx_interim_bit_pos;
    tx_next_busy = tx_interim_busy;
    tx_next_shift_reg = tx_shift_reg;
    tx_next_out_reg = tx_out_reg;
    
    if (baud_tick_tx_pipe) begin
      case (tx_state_pipe)
        TX_IDLE: begin
          if (tx_start) begin
            tx_next_shift_reg = tx_data;
          end
        end
        
        TX_START: begin
          tx_next_out_reg = 1'b0;
        end
        
        TX_DATA: begin
          tx_next_out_reg = tx_shift_reg[0];
          tx_next_shift_reg = {1'b0, tx_shift_reg[7:1]};
        end
        
        TX_STOP: begin
          tx_next_out_reg = 1'b1;
        end
      endcase
    end
  end
  
  // TX 时序逻辑 - 更新寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_state <= TX_IDLE;
      tx_out_reg <= 1'b1;
      tx_busy <= 1'b0;
      tx_bit_pos <= 3'd0;
      tx_shift_reg <= 8'd0;
    end else begin
      tx_state <= tx_next_state;
      tx_out_reg <= tx_next_out_reg;
      tx_busy <= tx_next_busy;
      tx_bit_pos <= tx_next_bit_pos;
      tx_shift_reg <= tx_next_shift_reg;
    end
  end
  
  // RX 组合逻辑第一阶段 - 状态转换判断
  reg [1:0] rx_interim_state;
  reg [2:0] rx_interim_bit_pos;
  reg rx_interim_ready;
  reg rx_interim_error;
  
  always @(*) begin
    // 默认保持当前状态
    rx_interim_state = rx_state_pipe;
    rx_interim_bit_pos = rx_bit_pos_pipe;
    rx_interim_ready = rx_ready;
    rx_interim_error = rx_error;
    
    if (baud_tick_rx_pipe) begin
      case (rx_state_pipe)
        RX_IDLE: begin
          if (rx_in_pipe == 1'b0) begin
            rx_interim_state = RX_START;
            rx_interim_ready = 1'b0;
          end
        end
        
        RX_START: begin
          rx_interim_state = RX_DATA;
          rx_interim_bit_pos = 3'd0;
        end
        
        RX_DATA: begin
          if (rx_bit_pos_pipe == 3'd7) begin
            rx_interim_state = RX_STOP;
          end else begin
            rx_interim_bit_pos = rx_bit_pos_pipe + 1'b1;
          end
        end
        
        RX_STOP: begin
          rx_interim_state = RX_IDLE;
          
          if (rx_in_pipe == 1'b1) begin
            rx_interim_ready = 1'b1;
            rx_interim_error = 1'b0;
          end else begin
            rx_interim_error = 1'b1;
          end
        end
        
        default: rx_interim_state = RX_IDLE;
      endcase
    end
  end
  
  // RX 组合逻辑第二阶段 - 数据操作
  always @(*) begin
    // 默认值保持
    rx_next_state = rx_interim_state;
    rx_next_bit_pos = rx_interim_bit_pos;
    rx_next_ready = rx_interim_ready;
    rx_next_error = rx_interim_error;
    rx_next_shift_reg = rx_shift_reg;
    rx_next_data = rx_data;
    
    if (baud_tick_rx_pipe) begin
      case (rx_state_pipe)
        RX_DATA: begin
          rx_next_shift_reg = {rx_in_pipe, rx_shift_reg[7:1]};
        end
        
        RX_STOP: begin
          if (rx_in_pipe == 1'b1) begin
            rx_next_data = rx_shift_reg;
          end
        end
      endcase
    end
  end
  
  // RX 时序逻辑 - 更新寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state <= RX_IDLE;
      rx_bit_pos <= 3'd0;
      rx_shift_reg <= 8'd0;
      rx_ready <= 1'b0;
      rx_error <= 1'b0;
      rx_data <= 8'd0;
    end else begin
      rx_state <= rx_next_state;
      rx_bit_pos <= rx_next_bit_pos;
      rx_shift_reg <= rx_next_shift_reg;
      rx_ready <= rx_next_ready;
      rx_error <= rx_next_error;
      rx_data <= rx_next_data;
    end
  end
endmodule