//SystemVerilog
// 顶层模块
module can_frame_parser(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  output reg [10:0] id,
  output reg [7:0] data [0:7],
  output reg [3:0] dlc,
  output reg rtr, ide, frame_valid
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // 内部信号
  wire [2:0] state;
  wire [7:0] bit_count;
  wire [7:0] byte_count;
  wire next_frame_valid;
  wire [10:0] next_id;
  wire next_rtr;
  wire next_ide;
  wire [3:0] next_dlc;
  wire [7:0] next_data [0:7];

  // 状态控制器实例
  can_state_controller state_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(state),
    .bit_count(bit_count),
    .byte_count(byte_count)
  );

  // ID处理器实例
  can_id_processor id_proc (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(state),
    .bit_count(bit_count),
    .id(id),
    .next_id(next_id),
    .rtr(rtr),
    .next_rtr(next_rtr)
  );

  // 控制字段处理器实例
  can_control_processor ctrl_proc (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(state),
    .bit_count(bit_count),
    .dlc(dlc),
    .next_dlc(next_dlc),
    .ide(ide),
    .next_ide(next_ide)
  );

  // 数据处理器实例
  can_data_processor data_proc (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(state),
    .bit_count(bit_count),
    .byte_count(byte_count),
    .dlc(dlc),
    .data(data),
    .next_data(next_data)
  );

  // 帧有效性处理器实例
  can_frame_validator frame_valid_proc (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .bit_valid(bit_valid),
    .state(state),
    .frame_valid(frame_valid),
    .next_frame_valid(next_frame_valid)
  );

  // 主寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      id <= 11'h0;
      rtr <= 1'b0;
      ide <= 1'b0;
      dlc <= 4'h0;
      frame_valid <= 1'b0;
      for (int i = 0; i < 8; i = i + 1) begin
        data[i] <= 8'h0;
      end
    end else begin
      id <= next_id;
      rtr <= next_rtr;
      ide <= next_ide;
      dlc <= next_dlc;
      frame_valid <= next_frame_valid;
      for (int i = 0; i < 8; i = i + 1) begin
        data[i] <= next_data[i];
      end
    end
  end
endmodule

// 状态控制器子模块
module can_state_controller(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  output reg [2:0] state,
  output reg [7:0] bit_count,
  output reg [7:0] byte_count
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // 内部信号
  reg [2:0] next_state;
  reg [7:0] next_bit_count;
  reg [7:0] next_byte_count;
  
  // 状态寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= WAIT_SOF;
      bit_count <= 8'h0;
      byte_count <= 8'h0;
    end else begin
      state <= next_state;
      bit_count <= next_bit_count;
      byte_count <= next_byte_count;
    end
  end
  
  // 状态转换逻辑
  always @(*) begin
    next_state = state;
    next_bit_count = bit_count;
    next_byte_count = byte_count;
    
    if (bit_valid) begin
      case (state)
        WAIT_SOF: begin
          if (bit_in == 1'b0) begin  // 开始帧（SOF）是显性位（0）
            next_state = GET_ID;
            next_bit_count = 8'h0;
          end
        end
        
        GET_ID: begin
          if (bit_count < 11) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_state = GET_CTRL;
            next_bit_count = 8'h0;
          end
        end
        
        GET_CTRL: begin
          if (bit_count < 6) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_state = GET_DATA;
            next_bit_count = 8'h0;
            next_byte_count = 8'h0;
          end
        end
        
        GET_DATA: begin
          if (bit_count < 7) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_bit_count = 8'h0;
            next_byte_count = byte_count + 1'b1;
            if (byte_count >= 7) begin  // 考虑到DLC可能指定更少的数据
              next_state = GET_CRC;
            end
          end
        end
        
        GET_CRC: begin
          if (bit_count < 15) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_state = GET_ACK;
            next_bit_count = 8'h0;
          end
        end
        
        GET_ACK: begin
          if (bit_count < 2) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_state = GET_EOF;
            next_bit_count = 8'h0;
          end
        end
        
        GET_EOF: begin
          if (bit_count < 7) begin
            next_bit_count = bit_count + 1'b1;
          end else begin
            next_state = WAIT_SOF;
            next_bit_count = 8'h0;
            next_byte_count = 8'h0;
          end
        end
      endcase
    end
  end
endmodule

// ID处理器子模块
module can_id_processor(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [2:0] state,
  input wire [7:0] bit_count,
  input wire [10:0] id,
  output reg [10:0] next_id,
  input wire rtr,
  output reg next_rtr
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // ID和RTR处理逻辑
  always @(*) begin
    next_id = id;
    next_rtr = rtr;
    
    if (bit_valid) begin
      case (state)
        GET_ID: begin
          if (bit_count < 11) begin
            next_id[10-bit_count] = bit_in;
          end else if (bit_count == 11) begin
            next_rtr = bit_in;
          end
        end
        default: ; // 保持当前值
      endcase
    end
  end
endmodule

// 控制字段处理器子模块
module can_control_processor(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [2:0] state,
  input wire [7:0] bit_count,
  input wire [3:0] dlc,
  output reg [3:0] next_dlc,
  input wire ide,
  output reg next_ide
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // 控制字段处理逻辑
  always @(*) begin
    next_dlc = dlc;
    next_ide = ide;
    
    if (bit_valid && state == GET_CTRL) begin
      case (bit_count)
        0: next_ide = bit_in;
        2, 3, 4, 5: next_dlc[5-bit_count] = bit_in;  // DLC字段为4位
        default: ; // 保持当前值
      endcase
    end
  end
endmodule

// 数据处理器子模块
module can_data_processor(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [2:0] state,
  input wire [7:0] bit_count,
  input wire [7:0] byte_count,
  input wire [3:0] dlc,
  input wire [7:0] data [0:7],
  output reg [7:0] next_data [0:7]
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  integer i;
  
  // 数据处理逻辑
  always @(*) begin
    for (i = 0; i < 8; i = i + 1) begin
      next_data[i] = data[i];
    end
    
    if (bit_valid && state == GET_DATA) begin
      // 只处理DLC指定的字节数
      if (byte_count < dlc) begin
        next_data[byte_count][7-bit_count] = bit_in;
      end
    end
  end
endmodule

// 帧有效性处理器子模块
module can_frame_validator(
  input wire clk, rst_n,
  input wire bit_in, bit_valid,
  input wire [2:0] state,
  input wire frame_valid,
  output reg next_frame_valid
);
  // FSM状态定义
  localparam WAIT_SOF=0, GET_ID=1, GET_CTRL=2, GET_DATA=3, GET_CRC=4, GET_ACK=5, GET_EOF=6;
  
  // 帧有效性处理逻辑
  always @(*) begin
    next_frame_valid = frame_valid;
    
    if (bit_valid) begin
      case (state)
        WAIT_SOF: next_frame_valid = 1'b0;
        GET_EOF: begin
          if (bit_in == 1'b1) begin  // EOF字段应该全为隐性位(1)
            next_frame_valid = 1'b1;
          end else begin
            next_frame_valid = 1'b0;
          end
        end
        default: ; // 保持当前值
      endcase
    end
  end
endmodule