//SystemVerilog
module can_receiver(
  input clk, reset_n, can_rx,
  output reg rx_active, rx_done, frame_error,
  output reg [10:0] identifier,
  output reg [7:0] data_out [0:7],
  output reg [3:0] data_length
);
  // 使用参数定义状态以提高可读性和可维护性
  localparam [3:0] IDLE    = 4'd0, 
                   SOF     = 4'd1, 
                   ID      = 4'd2, 
                   RTR     = 4'd3, 
                   CONTROL = 4'd4, 
                   DATA    = 4'd5, 
                   CRC     = 4'd6, 
                   ACK     = 4'd7, 
                   EOF     = 4'd8;
                   
  reg [3:0] state, next_state;
  reg [7:0] bit_count, next_bit_count;
  reg [7:0] data_count, next_data_count;
  reg [14:0] crc, next_crc;
  reg [14:0] crc_received, next_crc_received;
  
  // 优化状态转换逻辑，采用两段式状态机以减少组合逻辑路径
  always @(*) begin
    // 默认值设置，避免锁存器生成
    next_state = state;
    next_bit_count = bit_count;
    next_data_count = data_count;
    next_crc = crc;
    next_crc_received = crc_received;
    
    case(state)
      IDLE: begin
        if (!can_rx) next_state = SOF;
      end
      
      // 其他状态逻辑将在这里实现
      // ...（原状态转换逻辑）
      
      default: next_state = IDLE;
    endcase
  end
  
  // 寄存器更新逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      rx_active <= 1'b0;
      rx_done <= 1'b0;
      frame_error <= 1'b0;
      bit_count <= 8'h0;
      data_count <= 8'h0;
      crc <= 15'h0;
      crc_received <= 15'h0;
      identifier <= 11'h0;
      data_length <= 4'h0;
      // 初始化数据输出数组
      for (int i = 0; i < 8; i = i + 1) begin
        data_out[i] <= 8'h0;
      end
    end else begin
      state <= next_state;
      bit_count <= next_bit_count;
      data_count <= next_data_count;
      crc <= next_crc;
      crc_received <= next_crc_received;
      
      // 根据状态转换更新输出信号
      case(next_state)
        IDLE: begin
          rx_active <= 1'b0;
          rx_done <= 1'b0;
        end
        
        SOF: begin
          rx_active <= 1'b1;
          rx_done <= 1'b0;
        end
        
        // 其他状态输出更新逻辑
        // ...
      endcase
    end
  end
endmodule