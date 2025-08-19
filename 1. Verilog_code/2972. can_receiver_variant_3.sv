//SystemVerilog
module can_receiver (
  // 时钟和复位
  input  wire        clk,
  input  wire        reset_n,
  
  // CAN输入信号
  input  wire        can_rx,
  
  // AXI-Stream输出接口
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready,
  output wire [31:0] m_axis_tdata,
  output wire        m_axis_tlast,
  output wire [3:0]  m_axis_tuser
);

  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  
  // 内部寄存器
  reg [3:0]  state;
  reg [7:0]  bit_count, data_count;
  reg [14:0] crc, crc_received;
  reg        rx_active_reg, rx_done_reg, frame_error_reg;
  reg [10:0] identifier_reg;
  reg [7:0]  data_out_reg [0:7];
  reg [3:0]  data_length_reg;
  
  // 输出数据寄存器
  reg        output_valid_reg;
  reg [31:0] output_data_reg;
  reg        output_last_reg;
  reg [3:0]  output_user_reg;
  
  // AXI-Stream数据发送状态机参数
  localparam SEND_IDLE=0, SEND_ID=1, SEND_DATA1=2, SEND_DATA2=3, SEND_DONE=4;
  reg [2:0] axis_state;
  
  // 移除了输入寄存器前向重定时，直接使用输入信号
  wire can_rx_wire = can_rx;
  
  // CAN接收状态机
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      rx_active_reg <= 0;
      rx_done_reg <= 0;
      frame_error_reg <= 0;
      identifier_reg <= 0;
      data_length_reg <= 0;
      bit_count <= 0;
      data_count <= 0;
      crc <= 0;
      crc_received <= 0;
      for (int i = 0; i < 8; i++) begin
        data_out_reg[i] <= 0;
      end
    end else begin
      case(state)
        IDLE: begin
          // 直接基于输入can_rx进行状态转换，移除了寄存器延迟
          if (!can_rx_wire) begin 
            state <= SOF; 
            rx_active_reg <= 1; 
          end
        end
        // Additional state logic for CAN frame reception
        // 假设在某个状态完成接收
        EOF: begin
          rx_active_reg <= 0;
          rx_done_reg <= 1;
          // 设置接收完成
          state <= IDLE;
        end
      endcase
    end
  end
  
  // 在主逻辑后添加寄存器，前向重定时后的寄存信号捕获
  reg can_rx_delayed;
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      can_rx_delayed <= 1'b1; // CAN总线空闲状态为1
    end else begin
      can_rx_delayed <= can_rx_wire;
    end
  end
  
  // AXI-Stream发送状态机 - 新增
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      axis_state <= SEND_IDLE;
      output_valid_reg <= 1'b0;
      output_data_reg <= 32'h0;
      output_last_reg <= 1'b0;
      output_user_reg <= 4'h0;
    end else begin
      case (axis_state)
        SEND_IDLE: begin
          // 当CAN接收完成时启动传输
          if (rx_done_reg) begin
            output_valid_reg <= 1'b1;
            output_data_reg <= {21'h0, identifier_reg}; // 标识符
            output_user_reg <= {frame_error_reg, 3'b000}; // 用户字段包含错误标志
            output_last_reg <= (data_length_reg == 0); // 如果没有数据则这是最后一个传输
            axis_state <= SEND_ID;
          end else begin
            output_valid_reg <= 1'b0;
          end
        end
        
        SEND_ID: begin
          if (m_axis_tready && m_axis_tvalid) begin
            if (data_length_reg > 0) begin
              // 准备发送前4个数据字节
              output_data_reg <= {data_out_reg[3], data_out_reg[2], data_out_reg[1], data_out_reg[0]};
              output_last_reg <= (data_length_reg <= 4);
              axis_state <= SEND_DATA1;
            end else begin
              output_valid_reg <= 1'b0;
              axis_state <= SEND_DONE;
            end
          end
        end
        
        SEND_DATA1: begin
          if (m_axis_tready && m_axis_tvalid) begin
            if (data_length_reg > 4) begin
              // 准备发送剩余的数据字节
              output_data_reg <= {data_out_reg[7], data_out_reg[6], data_out_reg[5], data_out_reg[4]};
              output_last_reg <= 1'b1; // 最后一个数据包
              axis_state <= SEND_DATA2;
            end else begin
              output_valid_reg <= 1'b0;
              axis_state <= SEND_DONE;
            end
          end
        end
        
        SEND_DATA2: begin
          if (m_axis_tready && m_axis_tvalid) begin
            output_valid_reg <= 1'b0;
            axis_state <= SEND_DONE;
          end
        end
        
        SEND_DONE: begin
          // 等待CAN接收状态机重新进入IDLE状态
          if (!rx_done_reg) begin
            axis_state <= SEND_IDLE;
          end
        end
      endcase
    end
  end
  
  // AXI-Stream接口信号分配
  assign m_axis_tvalid = output_valid_reg;
  assign m_axis_tdata  = output_data_reg;
  assign m_axis_tlast  = output_last_reg;
  assign m_axis_tuser  = output_user_reg;

endmodule