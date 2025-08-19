//SystemVerilog
module uart_auto_baud (
  input wire clk, reset_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid,
  output reg [15:0] detected_baud
);
  // Auto-baud detection states
  localparam AB_IDLE = 0, AB_START = 1, AB_MEASURE = 2, AB_LOCK = 3;
  // UART receive states
  localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
  
  reg [1:0] ab_state;  // Auto-baud state
  reg [1:0] rx_state;  // Receiver state
  reg rx_prev;        // Previous RX value for edge detection
  
  reg [15:0] clk_counter;  // Clock counter for edge timing
  reg [15:0] baud_period;  // Measured baud period
  reg [15:0] bit_timer;    // Bit timing counter
  reg [2:0] bit_counter;   // Bit position counter
  
  // 添加高扇出信号的缓冲寄存器
  reg rx_buf1, rx_buf2;           // rx信号缓冲
  reg rx_prev_buf1, rx_prev_buf2; // rx_prev信号缓冲
  reg [15:0] clk_counter_buf1, clk_counter_buf2; // clk_counter信号缓冲
  reg [15:0] bit_timer_buf1, bit_timer_buf2;     // bit_timer信号缓冲
  
  // Auto-baud detection looks for 0x55 (U) character
  // which has 10101010 pattern (alternating edges)
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_buf1 <= 1;
      rx_buf2 <= 1;
      rx_prev_buf1 <= 1;
      rx_prev_buf2 <= 1;
    end else begin
      // 缓冲rx和rx_prev信号以减少扇出负载
      rx_buf1 <= rx;
      rx_buf2 <= rx;
      rx_prev_buf1 <= rx_prev;
      rx_prev_buf2 <= rx_prev;
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      ab_state <= AB_IDLE;
      clk_counter <= 0;
      baud_period <= 0;
      detected_baud <= 0;
      rx_prev <= 1;
      clk_counter_buf1 <= 0;
      clk_counter_buf2 <= 0;
    end else begin
      rx_prev <= rx_buf1; // 使用缓冲的rx信号
      
      // 缓冲clk_counter信号
      clk_counter_buf1 <= clk_counter;
      clk_counter_buf2 <= clk_counter;
      
      case (ab_state)
        AB_IDLE: begin
          if (rx_prev_buf1 == 1 && rx_buf1 == 0) begin // 使用缓冲的信号检测边沿
            ab_state <= AB_START;
            clk_counter <= 0;
          end
        end
        AB_START: begin
          clk_counter <= clk_counter + 1;
          if (rx_prev_buf1 == 0 && rx_buf1 == 1) begin // 使用缓冲的信号检测边沿
            ab_state <= AB_MEASURE;
            baud_period <= clk_counter;
            clk_counter <= 0;
          end
        end
        AB_MEASURE: begin
          clk_counter <= clk_counter + 1;
          if (rx_prev_buf1 != rx_buf1) begin // 使用缓冲的信号检测边沿
            if (clk_counter_buf1 >= baud_period/2) begin
              // Confirm measurement based on multiple edges
              ab_state <= AB_LOCK;
              detected_baud <= (16'd50_000_000 / baud_period); // Assuming 50MHz clock
            end
            clk_counter <= 0;
          end
        end
        AB_LOCK: begin
          // Auto-baud locked, no further adjustments
        end
      endcase
    end
  end
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_timer_buf1 <= 0;
      bit_timer_buf2 <= 0;
    end else begin
      // 缓冲bit_timer信号
      bit_timer_buf1 <= bit_timer;
      bit_timer_buf2 <= bit_timer;
    end
  end
  
  // UART receiver using the detected baud rate
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_state <= RX_IDLE;
      bit_timer <= 0;
      bit_counter <= 0;
      rx_data <= 0;
      rx_valid <= 0;
    end else if (ab_state == AB_LOCK) begin
      case (rx_state)
        RX_IDLE: begin
          rx_valid <= 0;
          if (rx_buf2 == 0) begin // 使用缓冲的rx信号检测起始位
            rx_state <= RX_START;
            bit_timer <= 0;
          end
        end
        RX_START: begin
          bit_timer <= bit_timer + 1;
          if (bit_timer_buf1 >= baud_period/2) begin // 使用缓冲的bit_timer
            rx_state <= RX_DATA;
            bit_timer <= 0;
            bit_counter <= 0;
          end
        end
        RX_DATA: begin
          bit_timer <= bit_timer + 1;
          if (bit_timer_buf2 >= baud_period) begin // 使用缓冲的bit_timer
            bit_timer <= 0;
            rx_data <= {rx_buf2, rx_data[7:1]}; // 使用缓冲的rx信号
            if (bit_counter == 7) rx_state <= RX_STOP;
            else bit_counter <= bit_counter + 1;
          end
        end
        RX_STOP: begin
          bit_timer <= bit_timer + 1;
          if (bit_timer_buf2 >= baud_period) begin // 使用缓冲的bit_timer
            if (rx_buf2 == 1) rx_valid <= 1; // 使用缓冲的rx信号检测停止位
            rx_state <= RX_IDLE;
          end
        end
      endcase
    end
  end
endmodule