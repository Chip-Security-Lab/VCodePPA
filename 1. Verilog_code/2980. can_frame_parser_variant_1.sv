//SystemVerilog
// 顶层模块
module can_frame_parser(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  output wire [10:0] id,
  output wire [7:0] data [0:7],
  output wire [3:0] dlc,
  output wire rtr, ide, frame_valid
);
  // 内部连线
  wire state_sof_detected;
  wire [2:0] parser_state;
  wire [7:0] bit_counter;
  wire [7:0] byte_counter;

  // 状态控制器子模块
  can_state_controller state_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .bit_counter(bit_counter),
    .byte_counter(byte_counter),
    .sof_detected(state_sof_detected),
    .state(parser_state)
  );

  // 位计数器子模块
  can_bit_counter bit_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .bit_valid(bit_valid),
    .state(parser_state),
    .sof_detected(state_sof_detected),
    .bit_counter(bit_counter),
    .byte_counter(byte_counter)
  );

  // 数据解析子模块
  can_data_parser data_parser (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(parser_state),
    .bit_counter(bit_counter),
    .byte_counter(byte_counter),
    .id(id),
    .data(data),
    .dlc(dlc),
    .rtr(rtr),
    .ide(ide),
    .frame_valid(frame_valid)
  );
endmodule

// 状态控制器子模块 - 负责CAN帧状态的转换逻辑
module can_state_controller (
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [7:0] bit_counter,
  input wire [7:0] byte_counter,
  output reg sof_detected,
  output reg [2:0] state
);
  // 状态定义
  localparam WAIT_SOF = 3'd0,
             GET_ID   = 3'd1,
             GET_CTRL = 3'd2,
             GET_DATA = 3'd3,
             GET_CRC  = 3'd4,
             GET_ACK  = 3'd5,
             GET_EOF  = 3'd6;

  // 状态转换逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= WAIT_SOF;
      sof_detected <= 1'b0;
    end else if (bit_valid) begin
      case (state)
        WAIT_SOF: begin
          if (bit_in == 1'b0) begin  // 开始帧检测
            state <= GET_ID;
            sof_detected <= 1'b1;
          end else begin
            sof_detected <= 1'b0;
          end
        end
        
        GET_ID: begin
          if (bit_counter >= 11) begin
            state <= GET_CTRL;
            sof_detected <= 1'b0;
          end
        end
        
        GET_CTRL: begin
          // 控制字段逻辑
          if (bit_counter >= 6) begin  // RTR + IDE + r0 + DLC (4位)
            state <= GET_DATA;
          end
        end
        
        GET_DATA: begin
          // 处理数据字段
          if (byte_counter >= dlc_value && bit_counter >= 7) begin
            state <= GET_CRC;
          end
        end
        
        GET_CRC: begin
          // CRC字段处理
          if (bit_counter >= 15) begin  // 15位CRC
            state <= GET_ACK;
          end
        end
        
        GET_ACK: begin
          // 应答字段处理
          if (bit_counter >= 2) begin  // ACK槽和分隔符
            state <= GET_EOF;
          end
        end
        
        GET_EOF: begin
          // 帧结束处理
          if (bit_counter >= 7) begin  // EOF字段为7位
            state <= WAIT_SOF;
          end
        end
      endcase
    end
  end
  
  // 这里为简化，假设DLC值为固定值4，实际应从控制字段提取
  localparam dlc_value = 4;
endmodule

// 位计数器子模块 - 负责跟踪位和字节计数
module can_bit_counter (
  input wire clk, rst_n,
  input wire bit_valid,
  input wire [2:0] state,
  input wire sof_detected,
  output reg [7:0] bit_counter,
  output reg [7:0] byte_counter
);
  // 状态定义
  localparam WAIT_SOF = 3'd0,
             GET_ID   = 3'd1,
             GET_CTRL = 3'd2,
             GET_DATA = 3'd3,
             GET_CRC  = 3'd4,
             GET_ACK  = 3'd5,
             GET_EOF  = 3'd6;
             
  // 位计数和字节计数逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      bit_counter <= 8'd0;
      byte_counter <= 8'd0;
    end else if (bit_valid) begin
      if (sof_detected) begin
        // 开始帧检测时重置计数器
        bit_counter <= 8'd0;
        byte_counter <= 8'd0;
      end else begin
        case (state)
          WAIT_SOF: begin
            bit_counter <= 8'd0;
            byte_counter <= 8'd0;
          end
          
          GET_ID: begin
            bit_counter <= bit_counter + 8'd1;
          end
          
          GET_CTRL: begin
            if (bit_counter >= 6) begin
              // 控制字段完成，重置位计数器
              bit_counter <= 8'd0;
            end else begin
              bit_counter <= bit_counter + 8'd1;
            end
          end
          
          GET_DATA: begin
            if (bit_counter >= 7) begin
              // 一个字节完成
              bit_counter <= 8'd0;
              byte_counter <= byte_counter + 8'd1;
            end else begin
              bit_counter <= bit_counter + 8'd1;
            end
          end
          
          default: begin
            // 其他状态简单递增位计数器
            bit_counter <= bit_counter + 8'd1;
          end
        endcase
      end
    end
  end
endmodule

// 数据解析子模块 - 负责解析CAN帧各个字段
module can_data_parser (
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [2:0] state,
  input wire [7:0] bit_counter, byte_counter,
  output reg [10:0] id,
  output reg [7:0] data [0:7],
  output reg [3:0] dlc,
  output reg rtr, ide, frame_valid
);
  // 状态定义
  localparam WAIT_SOF = 3'd0,
             GET_ID   = 3'd1,
             GET_CTRL = 3'd2,
             GET_DATA = 3'd3,
             GET_CRC  = 3'd4,
             GET_ACK  = 3'd5,
             GET_EOF  = 3'd6;

  // 数据解析逻辑
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id <= 11'd0;
      dlc <= 4'd0;
      rtr <= 1'b0;
      ide <= 1'b0;
      frame_valid <= 1'b0;
      for (int i = 0; i < 8; i++) begin
        data[i] <= 8'd0;
      end
    end else if (bit_valid) begin
      case (state)
        WAIT_SOF: begin
          frame_valid <= 1'b0;  // 清除帧有效标志
        end
        
        GET_ID: begin
          if (bit_counter < 11) begin
            // 标准标识符，从MSB到LSB
            id[10-bit_counter] <= bit_in;
          end else if (bit_counter == 11) begin
            // RTR位
            rtr <= bit_in;
          end
        end
        
        GET_CTRL: begin
          case (bit_counter)
            0: ide <= bit_in;  // IDE位
            // 1: r0 <= bit_in;  // 保留位 (未在输出中定义)
            2: dlc[3] <= bit_in;  // DLC位 [3]
            3: dlc[2] <= bit_in;  // DLC位 [2]
            4: dlc[1] <= bit_in;  // DLC位 [1]
            5: dlc[0] <= bit_in;  // DLC位 [0]
          endcase
        end
        
        GET_DATA: begin
          if (byte_counter < 8) begin
            data[byte_counter][7-bit_counter] <= bit_in;
          end
        end
        
        GET_EOF: begin
          if (bit_counter >= 6) begin
            // 帧结束时置位帧有效标志
            frame_valid <= 1'b1;
          end
        end
      endcase
    end
  end
endmodule