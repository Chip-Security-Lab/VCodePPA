//SystemVerilog
module mipi_slimbus_interface (
  input  wire        clk,
  input  wire        reset_n,
  
  // AXI-Stream输入接口
  input  wire        s_axis_tvalid,
  output wire        s_axis_tready,
  input  wire [31:0] s_axis_tdata,
  input  wire        s_axis_tlast,
  
  // AXI-Stream输出接口
  output wire        m_axis_tvalid,
  input  wire        m_axis_tready, 
  output wire [31:0] m_axis_tdata,
  output wire        m_axis_tlast,
  
  // 设备ID仍保留为常规输入
  input  wire [7:0]  device_id
);

  // 使用参数定义状态，提高可读性和合成效率
  localparam [1:0] SYNC = 2'b00, 
                   HEADER = 2'b01, 
                   DATA = 2'b10, 
                   CRC = 2'b11;
                  
  reg [1:0] state, next_state;
  reg [7:0] bit_counter, next_bit_counter;
  reg [9:0] frame_counter, next_frame_counter;
  reg next_data_valid;
  reg frame_sync_r, next_frame_sync;
  reg [31:0] received_data, next_received_data;
  
  // AXI-Stream 相关信号
  reg data_valid_r;
  reg [31:0] output_data;
  reg output_last;
  
  // 输入数据缓存
  reg input_data_bit;
  wire clock_in = clk; // 使用单一时钟域简化设计
  
  // AXI-Stream 接口映射
  assign s_axis_tready = (state == SYNC); // 当处于SYNC状态时准备好接收新数据
  assign m_axis_tvalid = data_valid_r;
  assign m_axis_tdata = output_data;
  assign m_axis_tlast = output_last;
  
  // 状态和计数器更新逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= SYNC;
      bit_counter <= 8'd0;
      frame_counter <= 10'd0;
      data_valid_r <= 1'b0;
      received_data <= 32'd0;
      frame_sync_r <= 1'b0;
      output_data <= 32'd0;
      output_last <= 1'b0;
    end else begin
      state <= next_state;
      bit_counter <= next_bit_counter;
      frame_counter <= next_frame_counter;
      data_valid_r <= next_data_valid;
      received_data <= next_received_data;
      frame_sync_r <= next_frame_sync;
      
      // 当数据有效时更新输出
      if (next_data_valid) begin
        output_data <= next_received_data;
        output_last <= (frame_counter >= 10'd500); // 在帧末尾设置TLAST
      end
    end
  end

  // 输入数据采样逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      input_data_bit <= 1'b0;
    end else if (s_axis_tvalid && s_axis_tready) begin
      input_data_bit <= s_axis_tdata[0]; // 采样输入数据的最低位
    end
  end

  // 组合逻辑，计算下一状态和信号
  always @* begin
    // 默认值保持不变
    next_state = state;
    next_bit_counter = bit_counter;
    next_frame_counter = (frame_counter == 10'd511) ? 10'd0 : frame_counter + 1'b1;
    next_data_valid = 1'b0; // 只在特定条件下设置为1
    next_received_data = received_data;
    next_frame_sync = 1'b0; // 默认为低电平

    case (state)
      SYNC: begin
        // 使用AXI-Stream输入触发状态转换
        if (frame_counter == 10'd511 && s_axis_tvalid) begin
          next_state = HEADER;
          next_frame_sync = 1'b1;
        end
      end
      
      HEADER: begin
        if (bit_counter < 8'd7) begin
          next_bit_counter = bit_counter + 1'b1;
          next_received_data = {received_data[30:0], input_data_bit};
        end 
        else if (bit_counter == 8'd7) begin
          next_bit_counter = bit_counter + 1'b1;
          next_received_data = {received_data[30:0], input_data_bit};
          // 立即检查设备ID匹配
          if (next_received_data[7:0] != device_id) begin
            next_state = SYNC;
            next_bit_counter = 8'd0;
          end
        end
        else if (bit_counter < 8'd14) begin
          next_bit_counter = bit_counter + 1'b1;
        end
        else begin // bit_counter == 14
          next_bit_counter = 8'd0;
          next_state = DATA;
        end
      end
      
      DATA: begin
        if (bit_counter < 8'd31) begin
          next_bit_counter = bit_counter + 1'b1;
          next_received_data = {received_data[30:0], input_data_bit};
        end else begin
          next_bit_counter = 8'd0;
          next_state = CRC;
        end
      end
      
      CRC: begin
        if (bit_counter < 8'd6) begin
          next_bit_counter = bit_counter + 1'b1;
        end else if (bit_counter == 8'd6) begin
          next_bit_counter = bit_counter + 1'b1;
          next_data_valid = 1'b1; // 数据有效标志，对应AXI-Stream的TVALID
          next_state = SYNC;
        end else begin
          next_bit_counter = 8'd0;
          next_state = SYNC;
        end
      end
      
      default: begin
        next_state = SYNC;
        next_bit_counter = 8'd0;
      end
    endcase
  end
  
  // 优化数据输出逻辑，并与AXI-Stream对接
  reg next_data_out;
  
  always @* begin
    next_data_out = (state == DATA && m_axis_tready) ? received_data[31] : 1'b0;
  end
  
  // 输出握手逻辑
  reg data_out_r;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      data_out_r <= 1'b0;
    end else if (m_axis_tready) begin
      data_out_r <= next_data_out;
    end
  end
endmodule