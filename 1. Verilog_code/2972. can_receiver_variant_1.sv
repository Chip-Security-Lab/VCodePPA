//SystemVerilog IEEE 1364-2005
module can_receiver(
  input clk, reset_n, can_rx,
  output reg rx_active, rx_done, frame_error,
  output reg [10:0] identifier,
  output reg [7:0] data_out [0:7],
  output reg [3:0] data_length
);
  // 状态定义使用参数化编码以优化状态机实现
  localparam [3:0] 
    IDLE    = 4'd0,
    SOF     = 4'd1,
    ID      = 4'd2,
    RTR     = 4'd3,
    CONTROL = 4'd4,
    DATA    = 4'd5,
    CRC     = 4'd6,
    ACK     = 4'd7,
    EOF     = 4'd8;
    
  // 流水线阶段信号
  reg [3:0] state_stage1, next_state_stage1;
  reg [3:0] state_stage2, next_state_stage2;
  reg [3:0] state_stage3;
  
  // 流水线控制信号
  reg valid_stage1, valid_stage2, valid_stage3;
  
  // 各阶段数据寄存器
  reg [6:0] bit_count_stage1, bit_count_stage2, bit_count_stage3;
  reg [2:0] data_count_stage1, data_count_stage2, data_count_stage3;
  reg [14:0] crc_stage1, crc_stage2, crc_stage3;
  reg [14:0] crc_received_stage1, crc_received_stage2, crc_received_stage3;
  
  // 流水线阶段1数据寄存器
  reg can_rx_stage1;
  
  // 流水线阶段2数据寄存器
  reg [10:0] identifier_stage2;
  reg [3:0] data_length_stage2;
  reg [7:0] data_stage2 [0:7];
  
  // 流水线阶段3数据寄存器（输出寄存器）
  reg rx_active_stage3;
  reg rx_done_stage3;
  reg frame_error_stage3;
  reg [10:0] identifier_stage3;
  reg [3:0] data_length_stage3;
  reg [7:0] data_stage3 [0:7];
  
  // 阶段1: 输入捕获和状态转换逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage1 <= IDLE;
      can_rx_stage1 <= 1'b1;
      valid_stage1 <= 1'b0;
      bit_count_stage1 <= 7'b0;
      data_count_stage1 <= 3'b0;
      crc_stage1 <= 15'b0;
      crc_received_stage1 <= 15'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      can_rx_stage1 <= can_rx;
      valid_stage1 <= 1'b1;
      
      // 位计数器逻辑
      if (state_stage1 == IDLE && !can_rx) begin
        bit_count_stage1 <= 7'b0;
      end else if (state_stage1 != next_state_stage1) begin
        bit_count_stage1 <= 7'b0;
      end else begin
        bit_count_stage1 <= bit_count_stage1 + 7'b1;
      end
      
      // 数据计数器逻辑
      if (state_stage1 == IDLE) begin
        data_count_stage1 <= 3'b0;
      end else if (state_stage1 == DATA && bit_count_stage1 == 7'b1000000) begin
        data_count_stage1 <= data_count_stage1 + 3'b1;
      end
      
      // CRC逻辑
      if (state_stage1 == IDLE) begin
        crc_stage1 <= 15'b0;
        crc_received_stage1 <= 15'b0;
      end else if (state_stage1 == ID || state_stage1 == RTR || 
                  state_stage1 == CONTROL || state_stage1 == DATA) begin
        // 简化的CRC计算逻辑
        crc_stage1 <= {crc_stage1[13:0], crc_stage1[14] ^ can_rx};
      end else if (state_stage1 == CRC) begin
        crc_received_stage1 <= {crc_received_stage1[13:0], can_rx};
      end
    end
  end

  // 阶段1: 状态转换计算
  always @(*) begin
    next_state_stage1 = state_stage1; // 默认保持当前状态
    
    case(state_stage1)
      IDLE:    next_state_stage1 = can_rx_stage1 ? IDLE : SOF;
      SOF:     next_state_stage1 = (bit_count_stage1 == 7'd0) ? ID : SOF;
      ID:      next_state_stage1 = (bit_count_stage1 == 7'd10) ? RTR : ID;
      RTR:     next_state_stage1 = (bit_count_stage1 == 7'd0) ? CONTROL : RTR;
      CONTROL: next_state_stage1 = (bit_count_stage1 == 7'd5) ? 
                                   (data_length_stage2 > 4'd0 ? DATA : CRC) : CONTROL;
      DATA:    next_state_stage1 = (bit_count_stage1 == 7'd7 && 
                                  data_count_stage1 == data_length_stage2 - 1) ? CRC : DATA;
      CRC:     next_state_stage1 = (bit_count_stage1 == 7'd14) ? ACK : CRC;
      ACK:     next_state_stage1 = (bit_count_stage1 == 7'd1) ? EOF : ACK;
      EOF:     next_state_stage1 = (bit_count_stage1 == 7'd6) ? IDLE : EOF;
      default: next_state_stage1 = IDLE;
    endcase
  end
  
  // 阶段2: 数据处理逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage2 <= IDLE;
      valid_stage2 <= 1'b0;
      identifier_stage2 <= 11'b0;
      data_length_stage2 <= 4'b0;
      bit_count_stage2 <= 7'b0;
      data_count_stage2 <= 3'b0;
      crc_stage2 <= 15'b0;
      crc_received_stage2 <= 15'b0;
      
      for (int i = 0; i < 8; i = i + 1) begin
        data_stage2[i] <= 8'b0;
      end
    end else begin
      state_stage2 <= state_stage1;
      valid_stage2 <= valid_stage1;
      bit_count_stage2 <= bit_count_stage1;
      data_count_stage2 <= data_count_stage1;
      crc_stage2 <= crc_stage1;
      crc_received_stage2 <= crc_received_stage1;
      
      // ID处理
      if (state_stage1 == ID) begin
        identifier_stage2[10 - bit_count_stage1] <= can_rx_stage1;
      end
      
      // 控制字段处理
      if (state_stage1 == CONTROL && bit_count_stage1 >= 7'd0 && bit_count_stage1 <= 7'd3) begin
        data_length_stage2[3 - bit_count_stage1] <= can_rx_stage1;
      end
      
      // 数据处理
      if (state_stage1 == DATA) begin
        data_stage2[data_count_stage1][7 - (bit_count_stage1 % 8)] <= can_rx_stage1;
      end
    end
  end
  
  // 阶段3: 输出生成
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_stage3 <= IDLE;
      valid_stage3 <= 1'b0;
      rx_active_stage3 <= 1'b0;
      rx_done_stage3 <= 1'b0;
      frame_error_stage3 <= 1'b0;
      identifier_stage3 <= 11'b0;
      data_length_stage3 <= 4'b0;
      bit_count_stage3 <= 7'b0;
      data_count_stage3 <= 3'b0;
      crc_stage3 <= 15'b0;
      crc_received_stage3 <= 15'b0;
      
      for (int i = 0; i < 8; i = i + 1) begin
        data_stage3[i] <= 8'b0;
      end
    end else begin
      state_stage3 <= state_stage2;
      valid_stage3 <= valid_stage2;
      bit_count_stage3 <= bit_count_stage2;
      data_count_stage3 <= data_count_stage2;
      crc_stage3 <= crc_stage2;
      crc_received_stage3 <= crc_received_stage2;
      identifier_stage3 <= identifier_stage2;
      data_length_stage3 <= data_length_stage2;
      
      for (int i = 0; i < 8; i = i + 1) begin
        data_stage3[i] <= data_stage2[i];
      end
      
      // 输出信号生成
      rx_done_stage3 <= 1'b0; // 默认值
      
      case(state_stage2)
        IDLE: begin
          rx_active_stage3 <= 1'b0;
          frame_error_stage3 <= 1'b0;
        end
        
        SOF: begin
          rx_active_stage3 <= 1'b1;
        end
        
        EOF: begin
          if (bit_count_stage2 == 7'd6) begin
            rx_done_stage3 <= 1'b1;
            // 检查CRC
            frame_error_stage3 <= (crc_stage2 != crc_received_stage2);
          end
        end
        
        default: begin
          // 保持当前状态
        end
      endcase
    end
  end
  
  // 输出寄存器连接
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      rx_active <= 1'b0;
      rx_done <= 1'b0;
      frame_error <= 1'b0;
      identifier <= 11'b0;
      data_length <= 4'b0;
      
      for (int i = 0; i < 8; i = i + 1) begin
        data_out[i] <= 8'b0;
      end
    end else if (valid_stage3) begin
      rx_active <= rx_active_stage3;
      rx_done <= rx_done_stage3;
      frame_error <= frame_error_stage3;
      identifier <= identifier_stage3;
      data_length <= data_length_stage3;
      
      for (int i = 0; i < 8; i = i + 1) begin
        data_out[i] <= data_stage3[i];
      end
    end
  end
endmodule