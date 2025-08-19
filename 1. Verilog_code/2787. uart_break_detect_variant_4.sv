//SystemVerilog
module uart_break_detect (
  input wire clock,
  input wire reset_n,
  
  // AXI-Stream input interface
  input wire        s_axis_tvalid,
  output wire       s_axis_tready,
  input wire        s_axis_tdata,  // rx_in bit
  
  // AXI-Stream output interface
  output reg        m_axis_tvalid,
  input wire        m_axis_tready,
  output reg [7:0]  m_axis_tdata,  // rx_data
  output reg        m_axis_tlast,  // break_detect signal
  
  // Debug output (optional, can be removed if not needed)
  output reg        break_detect
);
  // States - 使用独热编码提高状态机效率
  localparam [4:0] IDLE  = 5'b00001, 
                   START = 5'b00010, 
                   DATA  = 5'b00100, 
                   STOP  = 5'b01000, 
                   BREAK = 5'b10000;
  reg [4:0] state;
  
  // Counters
  reg [2:0] bit_counter;
  reg [3:0] break_counter; // Count consecutive zeros
  
  // Internal signals for rx processing
  wire rx_in = s_axis_tdata;
  reg  backpressure;       // Track backpressure condition
  
  // UART parameters
  localparam BREAK_THRESHOLD = 10; // Number of bits to detect break
  
  // 优化的信号，减少比较链
  wire break_threshold_reached = (break_counter >= BREAK_THRESHOLD - 1);
  wire data_complete = (bit_counter == 3'h7);
  
  // Handle s_axis_tready logic - we're ready when not blocked by downstream
  assign s_axis_tready = !backpressure && (state == IDLE || state == DATA);
  
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      bit_counter <= 0;
      break_counter <= 0;
      m_axis_tdata <= 0;
      m_axis_tvalid <= 0;
      m_axis_tlast <= 0;
      break_detect <= 0;
      backpressure <= 0;
    end else begin
      // Default values
      if (m_axis_tready && m_axis_tvalid) begin
        m_axis_tvalid <= 1'b0;
        m_axis_tlast <= 1'b0;
        backpressure <= 1'b0;
      end
      
      // 统一的break计数器逻辑 - only count when we have valid data
      if (s_axis_tvalid && s_axis_tready) begin
        if (rx_in) begin
          break_counter <= 0;
        end else if (state != IDLE || rx_in == 1'b0) begin
          // 只在非空闲状态或当接收到0时才增加计数器
          break_counter <= break_counter + 1'b1;
        end
      end
      
      case (state)
        IDLE: begin
          break_detect <= 1'b0;
          if (s_axis_tvalid && s_axis_tready && !rx_in) begin
            state <= START;
          end
        end
        
        START: begin
          if (s_axis_tvalid && s_axis_tready) begin
            state <= DATA;
            bit_counter <= 0;
          end
        end
        
        DATA: begin
          // Only process data when valid and ready
          if (s_axis_tvalid && s_axis_tready) begin
            // 优化的数据移位操作
            m_axis_tdata <= {rx_in, m_axis_tdata[7:1]};
            
            // 优化的计数器逻辑
            if (data_complete) begin
              state <= STOP;
            end else begin
              bit_counter <= bit_counter + 1'b1;
            end
            
            // 检查中断条件
            if (break_threshold_reached) begin
              state <= BREAK;
              break_detect <= 1'b1;
              m_axis_tlast <= 1'b1;
            end
          end
        end
        
        STOP: begin
          if (s_axis_tvalid && s_axis_tready) begin
            if (rx_in) begin // Valid stop bit
              m_axis_tvalid <= 1'b1;
              // Wait for downstream to accept data before moving to IDLE
              if (!m_axis_tready) begin
                backpressure <= 1'b1;
              end else begin
                state <= IDLE;
              end
            end else begin
              // 使用预计算的阈值检查
              if (break_threshold_reached) begin
                state <= BREAK;
                break_detect <= 1'b1;
                m_axis_tlast <= 1'b1;
                m_axis_tvalid <= 1'b1;
              end else begin
                state <= IDLE;
              end
            end
          end
        end
        
        BREAK: begin
          // 保持break_detect信号为高
          break_detect <= 1'b1;
          
          // Send break condition on AXI-Stream
          if (!m_axis_tvalid || (m_axis_tvalid && m_axis_tready)) begin
            m_axis_tvalid <= 1'b1;
            m_axis_tlast <= 1'b1;
          end
          
          // 优化的状态转换检测
          if (s_axis_tvalid && s_axis_tready && rx_in) begin
            // Wait for downstream to accept data before moving forward
            if (m_axis_tvalid && !m_axis_tready) begin
              backpressure <= 1'b1;
            end else begin
              state <= IDLE;
              m_axis_tlast <= 1'b0;
            end
          end
        end
        
        default: state <= IDLE;  // 添加默认情况保证状态机健壮性
      endcase
      
      // Handle backpressure resolution
      if (backpressure && m_axis_tready) begin
        backpressure <= 1'b0;
        state <= IDLE;
      end
    end
  end
endmodule