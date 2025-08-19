//SystemVerilog
module uart_interrupt #(parameter CLK_DIV = 16) (
  input wire clock, reset_n,
  input wire rx,
  output reg tx,
  input wire [7:0] tx_data,
  input wire tx_start,
  output reg [7:0] rx_data,
  output reg irq_tx_done, irq_rx_ready, irq_rx_break, irq_frame_err,
  input wire irq_tx_ack, irq_rx_ack, irq_break_ack, irq_frame_ack
);
  // 使用参数代替enum
  localparam RX_IDLE = 0, RX_START = 1, RX_DATA = 2, RX_STOP = 3;
  localparam TX_IDLE = 0, TX_START = 1, TX_DATA = 2, TX_STOP = 3;
  
  // 状态寄存器
  reg [1:0] rx_state_stage1, rx_state_stage2;
  reg [1:0] tx_state_stage1, tx_state_stage2;
  
  // 数据寄存器
  reg [7:0] rx_shift_stage1, rx_shift_stage2;
  reg [7:0] tx_shift_stage1, tx_shift_stage2;
  
  // 计数器寄存器
  reg [3:0] rx_bit_count_stage1, rx_bit_count_stage2;
  reg [3:0] tx_bit_count_stage1, tx_bit_count_stage2;
  reg [7:0] clk_div_count_stage1, clk_div_count_stage2;
  
  // 中间状态寄存器
  reg rx_break_detect_stage1, rx_break_detect_stage2;
  reg frame_error_stage1, frame_error_stage2;
  
  // 输入缓存
  reg rx_stage1, rx_stage2;
  reg tx_start_stage1, tx_start_stage2;
  reg [7:0] tx_data_stage1, tx_data_stage2;
  reg irq_rx_ack_stage1, irq_tx_ack_stage1, irq_break_ack_stage1, irq_frame_ack_stage1;
  
  // 前级计算结果传递寄存器
  reg [3:0] next_rx_bit_count_stage1;
  reg [3:0] next_tx_bit_count_stage1;
  reg [7:0] next_clk_div_count_stage1;
  
  // 前缀加法器的流水线分段
  // 第一级流水线: 计算P和G
  wire [7:0] p_rx_stage1, g_rx_stage1;
  wire [7:0] p_tx_stage1, g_tx_stage1;
  wire [7:0] p_clk_stage1, g_clk_stage1;
  
  reg [7:0] p_rx_stage2, g_rx_stage2;
  reg [7:0] p_tx_stage2, g_tx_stage2;
  reg [7:0] p_clk_stage2, g_clk_stage2;
  
  // 第二级流水线: 计算进位
  wire [7:0] c_rx_stage2, c_tx_stage2, c_clk_stage2;
  
  // 第三级流水线: 计算和
  wire [7:0] next_rx_bit_count_stage2;
  wire [7:0] next_tx_bit_count_stage2;
  wire [7:0] next_clk_div_count_stage2;
  
  // 第一级流水线: 计算P和G位
  assign p_rx_stage1 = {4'b0000, rx_bit_count_stage1} ^ 8'h01;
  assign g_rx_stage1 = {4'b0000, rx_bit_count_stage1} & 8'h01;
  
  assign p_tx_stage1 = {4'b0000, tx_bit_count_stage1} ^ 8'h01;
  assign g_tx_stage1 = {4'b0000, tx_bit_count_stage1} & 8'h01;
  
  assign p_clk_stage1 = clk_div_count_stage1 ^ 8'h01;
  assign g_clk_stage1 = clk_div_count_stage1 & 8'h01;
  
  // 第二级流水线: 计算进位
  assign c_rx_stage2[0] = g_rx_stage2[0];
  assign c_rx_stage2[1] = g_rx_stage2[1] | (p_rx_stage2[1] & c_rx_stage2[0]);
  assign c_rx_stage2[2] = g_rx_stage2[2] | (p_rx_stage2[2] & c_rx_stage2[1]);
  assign c_rx_stage2[3] = g_rx_stage2[3] | (p_rx_stage2[3] & c_rx_stage2[2]);
  assign c_rx_stage2[4] = g_rx_stage2[4] | (p_rx_stage2[4] & c_rx_stage2[3]);
  assign c_rx_stage2[5] = g_rx_stage2[5] | (p_rx_stage2[5] & c_rx_stage2[4]);
  assign c_rx_stage2[6] = g_rx_stage2[6] | (p_rx_stage2[6] & c_rx_stage2[5]);
  assign c_rx_stage2[7] = g_rx_stage2[7] | (p_rx_stage2[7] & c_rx_stage2[6]);
  
  assign c_tx_stage2[0] = g_tx_stage2[0];
  assign c_tx_stage2[1] = g_tx_stage2[1] | (p_tx_stage2[1] & c_tx_stage2[0]);
  assign c_tx_stage2[2] = g_tx_stage2[2] | (p_tx_stage2[2] & c_tx_stage2[1]);
  assign c_tx_stage2[3] = g_tx_stage2[3] | (p_tx_stage2[3] & c_tx_stage2[2]);
  assign c_tx_stage2[4] = g_tx_stage2[4] | (p_tx_stage2[4] & c_tx_stage2[3]);
  assign c_tx_stage2[5] = g_tx_stage2[5] | (p_tx_stage2[5] & c_tx_stage2[4]);
  assign c_tx_stage2[6] = g_tx_stage2[6] | (p_tx_stage2[6] & c_tx_stage2[5]);
  assign c_tx_stage2[7] = g_tx_stage2[7] | (p_tx_stage2[7] & c_tx_stage2[6]);
  
  assign c_clk_stage2[0] = g_clk_stage2[0];
  assign c_clk_stage2[1] = g_clk_stage2[1] | (p_clk_stage2[1] & c_clk_stage2[0]);
  assign c_clk_stage2[2] = g_clk_stage2[2] | (p_clk_stage2[2] & c_clk_stage2[1]);
  assign c_clk_stage2[3] = g_clk_stage2[3] | (p_clk_stage2[3] & c_clk_stage2[2]);
  assign c_clk_stage2[4] = g_clk_stage2[4] | (p_clk_stage2[4] & c_clk_stage2[3]);
  assign c_clk_stage2[5] = g_clk_stage2[5] | (p_clk_stage2[5] & c_clk_stage2[4]);
  assign c_clk_stage2[6] = g_clk_stage2[6] | (p_clk_stage2[6] & c_clk_stage2[5]);
  assign c_clk_stage2[7] = g_clk_stage2[7] | (p_clk_stage2[7] & c_clk_stage2[6]);
  
  // 第三级流水线: 计算结果
  assign next_rx_bit_count_stage2 = {4'b0000, rx_bit_count_stage2} ^ 8'h01 ^ {c_rx_stage2[6:0], 1'b0};
  assign next_tx_bit_count_stage2 = {4'b0000, tx_bit_count_stage2} ^ 8'h01 ^ {c_tx_stage2[6:0], 1'b0};
  assign next_clk_div_count_stage2 = clk_div_count_stage2 ^ 8'h01 ^ {c_clk_stage2[6:0], 1'b0};
  
  // 第一级流水线 - 寄存器更新和状态缓存
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      // 寄存器复位
      rx_stage1 <= 1'b1;
      rx_stage2 <= 1'b1;
      tx_start_stage1 <= 1'b0;
      tx_start_stage2 <= 1'b0;
      tx_data_stage1 <= 8'h00;
      tx_data_stage2 <= 8'h00;
      irq_rx_ack_stage1 <= 1'b0;
      irq_tx_ack_stage1 <= 1'b0;
      irq_break_ack_stage1 <= 1'b0;
      irq_frame_ack_stage1 <= 1'b0;
      
      // 流水线第一级寄存器复位
      rx_state_stage1 <= RX_IDLE;
      tx_state_stage1 <= TX_IDLE;
      rx_bit_count_stage1 <= 4'h0;
      tx_bit_count_stage1 <= 4'h0;
      rx_shift_stage1 <= 8'h00;
      tx_shift_stage1 <= 8'h00;
      clk_div_count_stage1 <= 8'h00;
      rx_break_detect_stage1 <= 1'b0;
      frame_error_stage1 <= 1'b0;
      
      // 第一级到第二级流水线传递寄存器复位
      p_rx_stage2 <= 8'h00;
      g_rx_stage2 <= 8'h00;
      p_tx_stage2 <= 8'h00;
      g_tx_stage2 <= 8'h00;
      p_clk_stage2 <= 8'h00;
      g_clk_stage2 <= 8'h00;
    end else begin
      // 输入信号缓存至第一级流水线
      rx_stage1 <= rx;
      tx_start_stage1 <= tx_start;
      tx_data_stage1 <= tx_data;
      irq_rx_ack_stage1 <= irq_rx_ack;
      irq_tx_ack_stage1 <= irq_tx_ack;
      irq_break_ack_stage1 <= irq_break_ack;
      irq_frame_ack_stage1 <= irq_frame_ack;
      
      // 第一级至第二级的P/G传递
      p_rx_stage2 <= p_rx_stage1;
      g_rx_stage2 <= g_rx_stage1;
      p_tx_stage2 <= p_tx_stage1;
      g_tx_stage2 <= g_tx_stage1;
      p_clk_stage2 <= p_clk_stage1;
      g_clk_stage2 <= g_clk_stage1;
    end
  end
  
  // 第二级流水线 - 状态更新和控制逻辑
  always @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
      // 流水线第二级寄存器复位
      rx_state_stage2 <= RX_IDLE;
      tx_state_stage2 <= TX_IDLE;
      rx_bit_count_stage2 <= 4'h0;
      tx_bit_count_stage2 <= 4'h0;
      rx_shift_stage2 <= 8'h00;
      tx_shift_stage2 <= 8'h00;
      clk_div_count_stage2 <= 8'h00;
      rx_break_detect_stage2 <= 1'b0;
      frame_error_stage2 <= 1'b0;
      
      // 输出寄存器复位
      rx_data <= 8'h00;
      tx <= 1'b1;
      irq_tx_done <= 1'b0;
      irq_rx_ready <= 1'b0;
      irq_rx_break <= 1'b0;
      irq_frame_err <= 1'b0;
    end else begin
      // 从第一级流水线获取状态到第二级
      rx_state_stage2 <= rx_state_stage1;
      tx_state_stage2 <= tx_state_stage1;
      rx_bit_count_stage2 <= rx_bit_count_stage1;
      tx_bit_count_stage2 <= tx_bit_count_stage1;
      rx_shift_stage2 <= rx_shift_stage1;
      tx_shift_stage2 <= tx_shift_stage1;
      clk_div_count_stage2 <= clk_div_count_stage1;
      rx_break_detect_stage2 <= rx_break_detect_stage1;
      frame_error_stage2 <= frame_error_stage1;
      
      // 输入信号缓存至第二级流水线
      rx_stage2 <= rx_stage1;
      tx_start_stage2 <= tx_start_stage1;
      tx_data_stage2 <= tx_data_stage1;
      
      // 中断处理
      if (irq_rx_ack_stage1) irq_rx_ready <= 1'b0;
      if (irq_break_ack_stage1) irq_rx_break <= 1'b0;
      if (irq_frame_ack_stage1) irq_frame_err <= 1'b0;
      if (irq_tx_ack_stage1) irq_tx_done <= 1'b0;
      
      // RX 状态机
      case (rx_state_stage2)
        RX_IDLE: begin
          if (rx_stage2 == 1'b0) begin
            rx_state_stage1 <= RX_START;
            rx_break_detect_stage1 <= 1'b1;
          end
        end
        
        RX_START: begin
          rx_state_stage1 <= RX_DATA;
          rx_bit_count_stage1 <= 4'h0;
        end
        
        RX_DATA: begin
          rx_shift_stage1 <= {rx_stage2, rx_shift_stage2[7:1]};
          if (rx_stage2 == 1'b1) rx_break_detect_stage1 <= 1'b0;
          
          if (rx_bit_count_stage2 == 4'h7) begin
            rx_state_stage1 <= RX_STOP;
          end else begin
            rx_bit_count_stage1 <= next_rx_bit_count_stage2[3:0];
          end
        end
        
        RX_STOP: begin
          rx_state_stage1 <= RX_IDLE;
          if (rx_stage2 == 1'b0) begin
            frame_error_stage1 <= 1'b1;
            irq_frame_err <= 1'b1;
          end else begin
            rx_data <= rx_shift_stage2;
            irq_rx_ready <= 1'b1;
          end
          
          if (rx_break_detect_stage2) begin
            irq_rx_break <= 1'b1;
            rx_break_detect_stage1 <= 1'b0;
          end
        end
        
        default: rx_state_stage1 <= RX_IDLE;
      endcase
      
      // TX 状态机
      if (clk_div_count_stage2 == CLK_DIV-1) begin
        clk_div_count_stage1 <= 8'h00;
        
        case (tx_state_stage2)
          TX_IDLE: begin
            if (tx_start_stage2) begin
              tx_state_stage1 <= TX_START;
              tx_shift_stage1 <= tx_data_stage2;
            end
          end
          
          TX_START: begin
            tx <= 1'b0;
            tx_state_stage1 <= TX_DATA;
            tx_bit_count_stage1 <= 4'h0;
          end
          
          TX_DATA: begin
            tx <= tx_shift_stage2[0];
            tx_shift_stage1 <= {1'b0, tx_shift_stage2[7:1]};
            
            if (tx_bit_count_stage2 == 4'h7) begin
              tx_state_stage1 <= TX_STOP;
            end else begin
              tx_bit_count_stage1 <= next_tx_bit_count_stage2[3:0];
            end
          end
          
          TX_STOP: begin
            tx <= 1'b1;
            tx_state_stage1 <= TX_IDLE;
            irq_tx_done <= 1'b1;
          end
          
          default: tx_state_stage1 <= TX_IDLE;
        endcase
      end else begin
        clk_div_count_stage1 <= next_clk_div_count_stage2[7:0];
      end
    end
  end
endmodule