//SystemVerilog
module can_overload_handler(
  input wire clk, rst_n,
  input wire can_rx, bit_timing,
  input wire frame_end, inter_frame_space,
  output reg overload_detected,
  output reg can_tx_overload
);
  // 流水线状态定义
  localparam IDLE = 0, DETECT = 1, FLAG = 2, DELIMITER = 3;
  
  // 流水线Stage1: 输入寄存和初始检测
  reg [2:0] state_stage1, next_state_stage1;
  reg [3:0] bit_counter_stage1, next_bit_counter_stage1;
  reg can_rx_stage1, frame_end_stage1, inter_frame_space_stage1;
  reg overload_flag_stage1, next_overload_flag_stage1;
  reg valid_stage1, next_valid_stage1;
  
  // 流水线Stage2: 状态处理和位计数
  reg [2:0] state_stage2, next_state_stage2;
  reg [3:0] bit_counter_stage2, next_bit_counter_stage2;
  reg overload_flag_stage2, next_overload_flag_stage2;
  reg valid_stage2, next_valid_stage2;
  
  // 流水线Stage3: 输出生成
  reg overload_detected_stage3, next_overload_detected_stage3;
  reg can_tx_overload_stage3, next_can_tx_overload_stage3;
  reg valid_stage3, next_valid_stage3;
  
  // Stage1: 输入寄存和初始检测
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_rx_stage1 <= 1'b1;
      frame_end_stage1 <= 1'b0;
      inter_frame_space_stage1 <= 1'b0;
      state_stage1 <= IDLE;
      bit_counter_stage1 <= 4'd0;
      overload_flag_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      can_rx_stage1 <= can_rx;
      frame_end_stage1 <= frame_end;
      inter_frame_space_stage1 <= inter_frame_space;
      state_stage1 <= next_state_stage1;
      bit_counter_stage1 <= next_bit_counter_stage1;
      overload_flag_stage1 <= next_overload_flag_stage1;
      valid_stage1 <= next_valid_stage1;
    end
  end
  
  // Stage1 组合逻辑
  always @(*) begin
    next_state_stage1 = state_stage1;
    next_bit_counter_stage1 = bit_counter_stage1;
    next_overload_flag_stage1 = overload_flag_stage1;
    next_valid_stage1 = 1'b0;
    
    if (bit_timing) begin
      next_valid_stage1 = 1'b1;
      
      case (state_stage1)
        IDLE: begin
          if (frame_end_stage1)
            next_state_stage1 = DETECT;
        end
        
        DETECT: begin
          if (inter_frame_space_stage1 && !can_rx_stage1) begin
            next_state_stage1 = FLAG;
            next_overload_flag_stage1 = 1'b1;
            next_bit_counter_stage1 = 4'd0;
          end
        end
        
        FLAG: begin
          next_bit_counter_stage1 = bit_counter_stage1 + 4'd1;
          if (bit_counter_stage1 >= 4'd5)
            next_state_stage1 = DELIMITER;
        end
        
        DELIMITER: begin
          next_bit_counter_stage1 = bit_counter_stage1 + 4'd1;
          if (bit_counter_stage1 >= 4'd7) begin
            next_state_stage1 = IDLE;
            next_overload_flag_stage1 = 1'b0;
          end
        end
      endcase
    end
  end
  
  // Stage2: 状态处理和位计数
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_stage2 <= IDLE;
      bit_counter_stage2 <= 4'd0;
      overload_flag_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= next_state_stage2;
      bit_counter_stage2 <= next_bit_counter_stage2;
      overload_flag_stage2 <= next_overload_flag_stage2;
      valid_stage2 <= next_valid_stage2;
    end
  end
  
  // Stage2 组合逻辑
  always @(*) begin
    next_state_stage2 = state_stage2;
    next_bit_counter_stage2 = bit_counter_stage2;
    next_overload_flag_stage2 = overload_flag_stage2;
    next_valid_stage2 = 1'b0;
    
    if (valid_stage1) begin
      next_valid_stage2 = 1'b1;
      next_state_stage2 = state_stage1;
      next_bit_counter_stage2 = bit_counter_stage1;
      next_overload_flag_stage2 = overload_flag_stage1;
    end
  end
  
  // Stage3: 输出生成
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      overload_detected_stage3 <= 1'b0;
      can_tx_overload_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
      
      // 模块输出寄存器
      overload_detected <= 1'b0;
      can_tx_overload <= 1'b0;
    end else begin
      overload_detected_stage3 <= next_overload_detected_stage3;
      can_tx_overload_stage3 <= next_can_tx_overload_stage3;
      valid_stage3 <= next_valid_stage3;
      
      // 只有当流水线Stage3有效时才更新输出
      if (valid_stage3) begin
        overload_detected <= overload_detected_stage3;
        can_tx_overload <= can_tx_overload_stage3;
      end
    end
  end
  
  // Stage3 组合逻辑
  always @(*) begin
    next_overload_detected_stage3 = overload_detected_stage3;
    next_can_tx_overload_stage3 = can_tx_overload_stage3;
    next_valid_stage3 = 1'b0;
    
    if (valid_stage2) begin
      next_valid_stage3 = 1'b1;
      
      // 根据状态生成输出
      case (state_stage2)
        IDLE, DETECT: begin
          next_overload_detected_stage3 = overload_flag_stage2;
          next_can_tx_overload_stage3 = 1'b0;
        end
        
        FLAG: begin
          next_overload_detected_stage3 = 1'b1;
          next_can_tx_overload_stage3 = 1'b1;
        end
        
        DELIMITER: begin
          next_overload_detected_stage3 = overload_flag_stage2;
          next_can_tx_overload_stage3 = 1'b0;
        end
      endcase
    end
  end
endmodule