//SystemVerilog
module can_sleep_controller(
  input wire clk, rst_n,
  input wire can_rx, activity_timeout,
  input wire sleep_request, wake_request,
  output reg can_sleep_mode,
  output reg can_wake_event,
  output reg power_down_enable
);
  // 状态编码
  localparam ACTIVE = 0, LISTEN_ONLY = 1, SLEEP_PENDING = 2, SLEEP = 3, WAKEUP = 4;
  
  // 寄存器声明
  reg [2:0] state;
  reg [15:0] timeout_counter;
  
  // 输入寄存器化 - 移动到输入处以减少输入到第一级寄存器的延迟
  reg can_rx_reg, activity_timeout_reg;
  reg sleep_request_reg, wake_request_reg;
  
  // 中间组合逻辑信号
  wire sleep_condition;
  wire wake_condition;
  wire timeout_reached;
  
  // 输入寄存器阶段 - 将寄存器移至输入端
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_reg <= 1'b1; // CAN总线空闲状态是高电平
      activity_timeout_reg <= 1'b0;
      sleep_request_reg <= 1'b0;
      wake_request_reg <= 1'b0;
    end else begin
      can_rx_reg <= can_rx;
      activity_timeout_reg <= activity_timeout;
      sleep_request_reg <= sleep_request;
      wake_request_reg <= wake_request;
    end
  end
  
  // 优化的组合逻辑，减少关键路径延迟
  assign timeout_reached = (timeout_counter >= 16'hFFFF) || activity_timeout_reg;
  assign sleep_condition = (state == ACTIVE) && sleep_request_reg;
  assign wake_condition = (state == SLEEP) && (wake_request_reg || !can_rx_reg);
  
  // 状态及输出逻辑更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ACTIVE;
      can_sleep_mode <= 1'b0;
      can_wake_event <= 1'b0;
      power_down_enable <= 1'b0;
      timeout_counter <= 16'h0000;
    end else begin
      // 默认值 - 保持当前状态
      can_wake_event <= 1'b0; // 默认不触发唤醒事件
      
      case (state)
        ACTIVE: begin
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          
          if (sleep_condition)
            state <= SLEEP_PENDING;
        end
        
        SLEEP_PENDING: begin
          timeout_counter <= timeout_counter + 1'b1;
          
          if (timeout_reached)
            state <= SLEEP;
        end
        
        SLEEP: begin
          can_sleep_mode <= 1'b1;
          power_down_enable <= 1'b1;
          
          if (wake_condition)
            state <= WAKEUP;
        end
        
        WAKEUP: begin
          can_wake_event <= 1'b1;
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          timeout_counter <= 16'h0000;
          state <= ACTIVE;
        end
        
        default: begin
          state <= ACTIVE;
          can_sleep_mode <= 1'b0;
          power_down_enable <= 1'b0;
          timeout_counter <= 16'h0000;
        end
      endcase
    end
  end
endmodule