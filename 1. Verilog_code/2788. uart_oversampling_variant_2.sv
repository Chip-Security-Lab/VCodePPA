//SystemVerilog
module uart_oversampling #(parameter CLK_FREQ = 48_000_000, BAUD = 115200) (
  input wire clk, rst_n,
  input wire rx,
  output reg [7:0] rx_data,
  output reg rx_valid
);
  // Calculate oversampling rate (16x standard)
  localparam OSR = 16;
  localparam CLKS_PER_BIT = CLK_FREQ / (BAUD * OSR);
  
  // State machine definitions
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state;
  
  // Counters
  reg [$clog2(CLKS_PER_BIT*OSR)-1:0] clk_counter;
  reg [3:0] os_counter; // Oversampling counter
  reg [2:0] bit_counter;
  
  // Sample registers
  reg [7:0] shift_reg;
  reg [OSR-1:0] sample_window;
  
  // 简化后的计数器增加逻辑
  wire [$clog2(CLKS_PER_BIT*OSR)-1:0] clk_counter_next;
  wire [3:0] os_counter_next;
  wire [2:0] bit_counter_next;
  
  // 直接使用加法替代复杂的前缀减法器
  assign clk_counter_next = clk_counter + 1'b1;
  assign os_counter_next = os_counter + 1'b1;
  assign bit_counter_next = bit_counter + 1'b1;
  
  // 简化的多数表决逻辑
  wire bit_value;
  reg [4:0] ones_count;
  
  // 计算采样窗口中1的数量
  always @(*) begin
    ones_count = 0;
    for (int i = 0; i < OSR; i = i + 1) begin
      ones_count = ones_count + sample_window[i];
    end
  end
  
  // 采用多数表决机制
  assign bit_value = ones_count > (OSR/2);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      clk_counter <= 0;
      os_counter <= 0;
      bit_counter <= 0;
      shift_reg <= 0;
      rx_data <= 0;
      rx_valid <= 0;
      sample_window <= 0;
    end else begin
      case (state)
        IDLE: begin
          rx_valid <= 0;
          if (!rx) begin // Start bit detected (简化条件检查)
            state <= START;
            clk_counter <= 0;
            os_counter <= 0;
          end
        end
        START: begin
          // Sample through the start bit to find center
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            if (os_counter == OSR/2) begin // Middle of start bit
              state <= DATA;
              bit_counter <= 0;
              sample_window <= 0; // 重置采样窗口
            end else os_counter <= os_counter_next;
          end else clk_counter <= clk_counter_next;
        end
        DATA: begin
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            
            // 更新采样窗口，使用移位而非重构整个window
            sample_window <= {sample_window[OSR-2:0], rx};
            
            if (os_counter == OSR-1) begin
              // 使用简化的多数表决逻辑
              shift_reg[bit_counter] <= bit_value;
              
              if (bit_counter == 7) begin
                state <= STOP;
                os_counter <= 0;
              end else bit_counter <= bit_counter_next;
            end else os_counter <= os_counter_next;
          end else clk_counter <= clk_counter_next;
        end
        STOP: begin
          if (clk_counter == CLKS_PER_BIT-1) begin
            clk_counter <= 0;
            if (os_counter == OSR/2) begin // Middle of stop bit
              state <= IDLE;
              rx_data <= shift_reg;
              rx_valid <= 1;
            end else os_counter <= os_counter_next;
          end else clk_counter <= clk_counter_next;
        end
      endcase
    end
  end
endmodule