//SystemVerilog
module can_sleep_controller(
  // Clock and Reset
  input wire clk,
  input wire rst_n,
  
  // AXI-Stream Slave Interface
  input wire        s_axis_tvalid,
  output reg        s_axis_tready,
  input wire [15:0] s_axis_tdata,
  input wire        s_axis_tlast,
  
  // AXI-Stream Master Interface
  output reg        m_axis_tvalid,
  input wire        m_axis_tready,
  output reg [15:0] m_axis_tdata,
  output reg        m_axis_tlast
);
  // 状态定义
  localparam [2:0] ACTIVE = 3'd0, 
                   LISTEN_ONLY = 3'd1, 
                   SLEEP_PENDING = 3'd2, 
                   SLEEP = 3'd3, 
                   WAKEUP = 3'd4;
                   
  reg [2:0] state, next_state;
  reg [15:0] timeout_counter;
  
  // 预处理输入信号以减少重复访问
  wire can_rx, activity_timeout, sleep_request, wake_request;
  reg can_sleep_mode, can_wake_event, power_down_enable;
  reg state_change;
  reg output_update_needed;
  
  // 映射AXI-Stream信号到内部控制信号
  assign can_rx = s_axis_tdata[0];
  assign activity_timeout = s_axis_tdata[1];
  assign sleep_request = s_axis_tdata[2];
  assign wake_request = s_axis_tdata[3];
  
  // 状态变化检测逻辑 - 拆分长路径
  always @(*) begin
    state_change = (state != next_state);
  end
  
  // 输出更新条件 - 拆分组合逻辑路径
  always @(*) begin
    output_update_needed = state_change || can_sleep_mode || can_wake_event || power_down_enable;
  end
  
  // AXI-Stream握手逻辑 - 优化时序路径
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s_axis_tready <= 1'b0;
      m_axis_tvalid <= 1'b0;
      m_axis_tdata <= 16'h0000;
      m_axis_tlast <= 1'b0;
    end else begin
      // 总是准备接收数据
      s_axis_tready <= 1'b1;
      
      // 更新主接口 - 分解条件判断以优化关键路径
      if (output_update_needed) begin
        m_axis_tvalid <= 1'b1;
        m_axis_tdata <= {13'b0, power_down_enable, can_wake_event, can_sleep_mode};
        m_axis_tlast <= (state == WAKEUP); // 在唤醒转换时断言tlast
      end else if (m_axis_tready) begin
        m_axis_tvalid <= 1'b0;
      end
    end
  end
  
  // 状态机计算逻辑 - 从主状态机分离出来以平衡路径
  always @(*) begin
    // 默认保持当前状态
    next_state = state;
    
    case (state)
      ACTIVE: begin
        if (s_axis_tvalid && sleep_request)
          next_state = SLEEP_PENDING;
      end
      
      SLEEP_PENDING: begin
        if (s_axis_tvalid) begin
          if (timeout_counter >= 16'hFFFF || activity_timeout)
            next_state = SLEEP;
        end
      end
      
      SLEEP: begin
        if (s_axis_tvalid && (wake_request || !can_rx))
          next_state = WAKEUP;
      end
      
      WAKEUP: begin
        next_state = ACTIVE;
      end
      
      default: begin
        next_state = ACTIVE;
      end
    endcase
  end
  
  // 主控制器状态机 - 负责状态更新和输出控制
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ACTIVE;
      can_sleep_mode <= 1'b0;
      can_wake_event <= 1'b0;
      power_down_enable <= 1'b0;
      timeout_counter <= 16'h0000;
    end else begin
      state <= next_state;
      
      // 分离超时计数器更新逻辑，减少关键路径
      if (state == SLEEP_PENDING && s_axis_tvalid) begin
        timeout_counter <= timeout_counter + 1'b1;
      end else if (state == ACTIVE) begin
        timeout_counter <= 16'h0000;
      end
      
      // 根据状态设置控制信号 - 分解为更简单的逻辑
      case (state)
        ACTIVE: begin
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          can_wake_event <= 1'b0;
        end
        
        SLEEP: begin
          can_sleep_mode <= 1'b1;
          power_down_enable <= 1'b1;
        end
        
        WAKEUP: begin
          can_wake_event <= 1'b1;
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
        end
        
        default: begin
          // 保持当前值
        end
      endcase
    end
  end
endmodule