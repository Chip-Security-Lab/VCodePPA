//SystemVerilog
module can_sleep_controller (
  // AXI-Stream接口 - 时钟和复位
  input  wire        s_axis_aclk,
  input  wire        s_axis_aresetn,
  
  // AXI-Stream输入接口
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [15:0] s_axis_tdata,
  input  wire        s_axis_tlast,
  
  // AXI-Stream输出接口
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [15:0] m_axis_tdata,
  output wire        m_axis_tlast
);

  // 状态编码优化：使用独热编码以提高状态机效率
  localparam [4:0] ACTIVE        = 5'b00001,
                   LISTEN_ONLY   = 5'b00010,
                   SLEEP_PENDING = 5'b00100,
                   SLEEP         = 5'b01000,
                   WAKEUP        = 5'b10000;
  
  reg [4:0]  state, next_state;
  reg [15:0] timeout_counter;
  
  // 从AXI-Stream接口提取控制信号 - 使用位段选择提高可读性
  wire [3:0] control_signals = s_axis_tdata[3:0];
  wire can_rx           = control_signals[0];
  wire activity_timeout = control_signals[1];
  wire sleep_request    = control_signals[2];
  wire wake_request     = control_signals[3];
  
  // 输出信号寄存器
  reg can_sleep_mode;
  reg can_wake_event;
  reg power_down_enable;
  
  // AXI-Stream握手和控制信号
  reg  s_axis_data_received;
  reg  m_axis_data_valid;
  reg  processing_done;
  
  // 输入AXI-Stream握手逻辑 - 优化条件判断
  assign s_axis_tready = (state != SLEEP); 
  
  // 输出AXI-Stream信号封装
  assign m_axis_tvalid = m_axis_data_valid;
  assign m_axis_tdata  = {{13{1'b0}}, power_down_enable, can_wake_event, can_sleep_mode};
  assign m_axis_tlast  = processing_done;
  
  // 优化的状态转换逻辑 - 使用更清晰的状态转换判断
  always @(posedge s_axis_aclk or negedge s_axis_aresetn) begin
    if (!s_axis_aresetn) begin
      // 异步复位 - 分组初始化
      state <= ACTIVE;
      next_state <= ACTIVE;
      
      // 控制输出初始化
      can_sleep_mode <= 1'b0;
      can_wake_event <= 1'b0;
      power_down_enable <= 1'b0;
      
      // 计数器和握手信号初始化
      timeout_counter <= 16'b0;
      m_axis_data_valid <= 1'b0;
      processing_done <= 1'b0;
      s_axis_data_received <= 1'b0;
    end else begin
      // 数据接收逻辑 - 优化逻辑表达式
      s_axis_data_received <= (s_axis_tvalid && s_axis_tready) ? 1'b1 : 
                             (m_axis_tvalid && m_axis_tready) ? 1'b0 : s_axis_data_received;
      
      // 状态更新
      state <= next_state;
      
      // 重置输出有效信号 - 提前处理共享逻辑
      if (m_axis_tvalid && m_axis_tready) begin
        m_axis_data_valid <= 1'b0;
        // 只在WAKEUP状态下重置唤醒事件标志
        can_wake_event <= (state == WAKEUP) ? 1'b0 : can_wake_event;
      end

      // 状态机逻辑 - 优化状态转换和条件判断
      case (state)
        ACTIVE: begin
          // 基础状态设置
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          processing_done <= 1'b0;
          
          // 优化条件分支结构
          if (s_axis_data_received) begin
            m_axis_data_valid <= 1'b1;
            next_state <= sleep_request ? SLEEP_PENDING : ACTIVE;
          end else begin
            next_state <= ACTIVE;
          end
        end
        
        SLEEP_PENDING: begin
          // 递增计数器 - 使用溢出检测优化超时判断
          timeout_counter <= timeout_counter + 1'b1;
          processing_done <= 1'b0;
          
          // 改进的超时条件判断 - 使用更高效的比较
          if (activity_timeout || &timeout_counter) begin
            next_state <= SLEEP;
            m_axis_data_valid <= 1'b1;
          end else begin
            next_state <= SLEEP_PENDING;
          end
        end
        
        SLEEP: begin
          // 睡眠模式设置
          can_sleep_mode <= 1'b1;
          power_down_enable <= 1'b1;
          processing_done <= 1'b1;
          
          // 优化唤醒条件检测 - 使用简化的逻辑表达式
          if (s_axis_data_received && (wake_request || !can_rx)) begin
            next_state <= WAKEUP;
            m_axis_data_valid <= 1'b1;
          end else begin
            next_state <= SLEEP;
          end
        end
        
        WAKEUP: begin
          // 唤醒事件设置
          can_wake_event <= 1'b1;
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          processing_done <= 1'b1;
          m_axis_data_valid <= 1'b1;
          next_state <= ACTIVE;
        end
        
        default: begin
          // 安全状态转换
          next_state <= ACTIVE;
        end
      endcase
    end
  end
  
endmodule