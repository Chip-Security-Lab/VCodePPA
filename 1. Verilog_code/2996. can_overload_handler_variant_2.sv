//SystemVerilog
//IEEE 1364-2005 Verilog
module can_overload_handler(
  input wire clk, rst_n,
  
  // 输入接口
  input wire can_rx,
  input wire bit_timing,
  input wire frame_end, 
  input wire inter_frame_space,
  input wire in_valid,    // 输入有效信号
  output wire in_ready,   // 输入就绪信号
  
  // 输出接口
  output reg overload_detected,
  output reg can_tx_overload,
  output reg out_valid,   // 输出有效信号
  input wire out_ready    // 输出就绪信号
);
  // 状态寄存器定义
  reg [2:0] state, next_state;
  reg [3:0] bit_counter, next_bit_counter;
  reg next_overload_detected, next_can_tx_overload;
  reg next_out_valid;
  
  // 前馈寄存器 - 捕获输入信号
  reg can_rx_reg, bit_timing_reg, frame_end_reg, inter_frame_space_reg, in_valid_reg, out_ready_reg;
  
  // 状态参数定义
  localparam IDLE = 0, DETECT = 1, FLAG = 2, DELIMITER = 3, WAIT_READY = 4;
  
  // 输入就绪信号逻辑 - 使用寄存器版本的信号
  assign in_ready = (state == IDLE || state == DETECT) && !out_valid || (out_valid && out_ready_reg);
  
  // 输入信号寄存器化
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_reg <= 1;  // CAN总线空闲态为隐性(1)
      bit_timing_reg <= 0;
      frame_end_reg <= 0;
      inter_frame_space_reg <= 0;
      in_valid_reg <= 0;
      out_ready_reg <= 0;
    end else begin
      can_rx_reg <= can_rx;
      bit_timing_reg <= bit_timing;
      frame_end_reg <= frame_end;
      inter_frame_space_reg <= inter_frame_space;
      in_valid_reg <= in_valid;
      out_ready_reg <= out_ready;
    end
  end
  
  // 组合逻辑部分 - 计算下一状态和输出
  always @(*) begin
    // 默认值保持当前状态
    next_state = state;
    next_bit_counter = bit_counter;
    next_overload_detected = overload_detected;
    next_can_tx_overload = can_tx_overload;
    next_out_valid = out_valid;
    
    case (state)
      IDLE: begin
        if (in_valid_reg && in_ready && frame_end_reg)
          next_state = DETECT;
      end
      
      DETECT: begin
        // 检测过载条件(在帧间空间内的显性位)
        if (in_valid_reg && in_ready && inter_frame_space_reg && !can_rx_reg) begin
          next_state = FLAG;
          next_overload_detected = 1;
          next_bit_counter = 0;
        end
      end
      
      FLAG: begin
        // 仅在bit_timing有效时更新
        if (bit_timing_reg) begin
          // 发送6个显性位
          next_can_tx_overload = 1;
          next_bit_counter = bit_counter + 1;
          if (bit_counter >= 5)
            next_state = DELIMITER;
        end
      end
      
      DELIMITER: begin
        // 仅在bit_timing有效时更新
        if (bit_timing_reg) begin
          // 发送8个隐性位
          next_can_tx_overload = 0;
          next_bit_counter = bit_counter + 1;
          if (bit_counter >= 7) begin
            next_state = WAIT_READY;
            next_overload_detected = 0;
            next_out_valid = 1;
          end
        end
      end
      
      WAIT_READY: begin
        if (out_ready_reg) begin
          next_state = IDLE;
          next_out_valid = 0;
        end
      end
    endcase
  end
  
  // 时序逻辑部分 - 更新寄存器
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_counter <= 0;
      overload_detected <= 0;
      can_tx_overload <= 0;
      out_valid <= 0;
    end else begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      overload_detected <= next_overload_detected;
      can_tx_overload <= next_can_tx_overload;
      out_valid <= next_out_valid;
    end
  end
endmodule