//SystemVerilog
module uart_error_detect (
  input wire clk, rst_n,
  input wire serial_in,
  output reg [7:0] rx_data,
  output reg data_valid,
  output reg framing_error, parity_error, overrun_error
);
  // 增加流水线级数的状态机定义
  localparam IDLE = 4'd0, START = 4'd1, DATA1 = 4'd2, DATA2 = 4'd3, 
             DATA3 = 4'd4, PARITY1 = 4'd5, PARITY2 = 4'd6, 
             STOP1 = 4'd7, STOP2 = 4'd8;
  
  reg [3:0] state, next_state;
  reg [2:0] bit_count, bit_count_next;
  reg [7:0] shift_reg, shift_reg_next;
  reg parity_bit, parity_bit_next;
  reg data_ready, data_ready_next;
  reg prev_data_ready, prev_data_ready_next;
  reg serial_in_stage1, serial_in_stage2;
  reg framing_error_next, parity_error_next, overrun_error_next;
  reg data_valid_next;
  reg [7:0] rx_data_next;
  
  // 先行进位加法器信号
  wire [3:0] p, g;  // 传播和生成信号
  wire [3:0] c;     // 进位信号
  
  // 拆分加法器计算为流水线阶段
  reg [3:0] bit_count_stage1;
  reg [3:0] carry_stage1;
  reg [3:0] sum_stage1;
  
  // 状态机和数据处理流水线
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      bit_count <= 0;
      shift_reg <= 0;
      parity_bit <= 0;
      framing_error <= 0;
      parity_error <= 0;
      overrun_error <= 0;
      data_valid <= 0;
      data_ready <= 0;
      prev_data_ready <= 0;
      rx_data <= 0;
      serial_in_stage1 <= 1'b1;
      serial_in_stage2 <= 1'b1;
      bit_count_stage1 <= 0;
      carry_stage1 <= 0;
      sum_stage1 <= 0;
    end else begin
      // 流水线阶段1：输入信号缓存
      serial_in_stage1 <= serial_in;
      serial_in_stage2 <= serial_in_stage1;
      
      // 流水线阶段2：状态和计数器更新
      state <= next_state;
      bit_count <= bit_count_next;
      shift_reg <= shift_reg_next;
      parity_bit <= parity_bit_next;
      data_ready <= data_ready_next;
      prev_data_ready <= prev_data_ready_next;
      
      // 流水线阶段3：错误检测和输出生成
      framing_error <= framing_error_next;
      parity_error <= parity_error_next;
      overrun_error <= overrun_error_next;
      data_valid <= data_valid_next;
      rx_data <= rx_data_next;
      
      // 计数器加法流水线
      bit_count_stage1 <= {1'b0, bit_count};
      carry_stage1 <= c;
      sum_stage1 <= {1'b0, bit_count} ^ 4'b0001;
    end
  end
  
  // 使用先行进位加法器计算bit_count+1
  assign p = bit_count_stage1 | 4'b0001;  // 传播信号
  assign g = bit_count_stage1 & 4'b0001;  // 生成信号
  
  // 计算进位 - 拆分为流水线阶段
  assign c[0] = 1'b0;
  assign c[1] = g[0] | (p[0] & c[0]);
  assign c[2] = g[1] | (p[1] & c[1]);
  assign c[3] = g[2] | (p[2] & c[2]);
  
  // 流水线状态机和数据通路控制逻辑
  always @(*) begin
    // 默认保持当前值
    next_state = state;
    bit_count_next = bit_count;
    shift_reg_next = shift_reg;
    parity_bit_next = parity_bit;
    data_ready_next = data_ready;
    prev_data_ready_next = data_ready;
    framing_error_next = framing_error;
    parity_error_next = parity_error;
    overrun_error_next = overrun_error;
    data_valid_next = 0; // 默认不激活
    rx_data_next = rx_data;
    
    case (state)
      IDLE: begin
        if (serial_in_stage2 == 1'b0) begin
          next_state = START;
        end
        if (data_ready && !prev_data_ready) begin
          rx_data_next = shift_reg;
          data_valid_next = 1;
        end
      end
      
      START: begin
        next_state = DATA1;
        bit_count_next = 0;
        shift_reg_next = 0;
        parity_bit_next = 0;
      end
      
      DATA1: begin
        next_state = DATA2;
        // 第一阶段数据接收
        if (bit_count < 4) begin
          shift_reg_next = {serial_in_stage2, shift_reg[7:1]};
          parity_bit_next = parity_bit ^ serial_in_stage2;
          bit_count_next = sum_stage1[2:0] | (carry_stage1[2:0] & 3'b111);
        end
      end
      
      DATA2: begin
        next_state = DATA3;
        // 第二阶段数据接收
        if (bit_count >= 4 && bit_count < 7) begin
          shift_reg_next = {serial_in_stage2, shift_reg[7:1]};
          parity_bit_next = parity_bit ^ serial_in_stage2;
          bit_count_next = sum_stage1[2:0] | (carry_stage1[2:0] & 3'b111);
        end
      end
      
      DATA3: begin
        // 最后一位数据接收
        if (bit_count == 7) begin
          shift_reg_next = {serial_in_stage2, shift_reg[7:1]};
          parity_bit_next = parity_bit ^ serial_in_stage2;
          next_state = PARITY1;
        end else begin
          next_state = DATA1;
        end
      end
      
      PARITY1: begin
        next_state = PARITY2;
        // 奇偶校验第一阶段
      end
      
      PARITY2: begin
        next_state = STOP1;
        // 奇偶校验第二阶段，完成校验
        parity_error_next = (parity_bit == serial_in_stage2); // Odd parity check
      end
      
      STOP1: begin
        next_state = STOP2;
        // 停止位第一阶段
      end
      
      STOP2: begin
        next_state = IDLE;
        // 停止位第二阶段，完成错误检测
        framing_error_next = (serial_in_stage2 == 0); // STOP bit should be 1
        overrun_error_next = data_ready && !prev_data_ready && !data_valid;
        data_ready_next = 1;
      end
      
      default: next_state = IDLE;
    endcase
  end
endmodule