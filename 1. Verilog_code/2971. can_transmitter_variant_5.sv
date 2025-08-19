//SystemVerilog - IEEE 1364-2005
module can_transmitter(
  input clk, reset_n, tx_start,
  input [10:0] identifier,
  input [7:0] data_in,
  input [3:0] data_length,
  output reg tx_active, tx_done,
  output reg can_tx
);
  // 内部接线声明
  wire state_sof, state_id, state_rtr, state_control, state_data, state_crc, state_ack, state_eof;
  wire [3:0] state, next_state;
  wire tx_start_synced;
  wire [14:0] crc_value;
  wire [7:0] bit_count, data_count;

  // 同步输入模块实例化
  input_synchronizer input_sync_inst (
    .clk(clk),
    .reset_n(reset_n),
    .tx_start(tx_start),
    .tx_start_synced(tx_start_synced)
  );

  // 状态控制器模块实例化
  state_controller state_ctrl_inst (
    .clk(clk),
    .reset_n(reset_n),
    .tx_start_synced(tx_start_synced),
    .state(state),
    .next_state(next_state),
    .state_sof(state_sof),
    .state_id(state_id),
    .state_rtr(state_rtr),
    .state_control(state_control),
    .state_data(state_data),
    .state_crc(state_crc),
    .state_ack(state_ack),
    .state_eof(state_eof)
  );

  // 位计数器模块实例化
  bit_counter bit_counter_inst (
    .clk(clk),
    .reset_n(reset_n),
    .state(state),
    .bit_count(bit_count),
    .data_count(data_count)
  );

  // CRC生成器模块实例化
  crc_generator crc_gen_inst (
    .clk(clk),
    .reset_n(reset_n),
    .state(state),
    .identifier(identifier),
    .data_in(data_in),
    .data_length(data_length),
    .bit_count(bit_count),
    .crc_value(crc_value)
  );

  // 输出控制器模块实例化
  output_controller output_ctrl_inst (
    .clk(clk),
    .reset_n(reset_n),
    .state(state),
    .identifier(identifier),
    .data_in(data_in),
    .crc_value(crc_value),
    .bit_count(bit_count),
    .data_count(data_count),
    .tx_active(tx_active),
    .tx_done(tx_done),
    .can_tx(can_tx)
  );
endmodule

//同步输入模块
module input_synchronizer (
  input clk, reset_n, tx_start,
  output reg tx_start_synced
);
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) 
      tx_start_synced <= 1'b0;
    else
      tx_start_synced <= tx_start;
  end
endmodule

//状态控制器模块
module state_controller (
  input clk, reset_n, tx_start_synced,
  output reg [3:0] state,
  output reg [3:0] next_state,
  output state_sof, state_id, state_rtr, state_control, state_data, state_crc, state_ack, state_eof
);
  // 状态参数定义
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  
  // 状态译码输出
  assign state_sof = (state == SOF);
  assign state_id = (state == ID);
  assign state_rtr = (state == RTR);
  assign state_control = (state == CONTROL);
  assign state_data = (state == DATA);
  assign state_crc = (state == CRC);
  assign state_ack = (state == ACK);
  assign state_eof = (state == EOF);
  
  // 状态转换逻辑
  always @(*) begin
    case(state)
      IDLE: next_state = tx_start_synced ? SOF : IDLE;
      SOF: next_state = ID;
      ID: next_state = RTR;
      RTR: next_state = CONTROL;
      CONTROL: next_state = DATA;
      DATA: next_state = CRC;
      CRC: next_state = ACK;
      ACK: next_state = EOF;
      EOF: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
  
  // 状态寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) 
      state <= IDLE;
    else 
      state <= next_state;
  end
endmodule

//位计数器模块
module bit_counter (
  input clk, reset_n,
  input [3:0] state,
  output reg [7:0] bit_count,
  output reg [7:0] data_count
);
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      bit_count <= 8'b0;
      data_count <= 8'b0;
    end else begin
      case(state)
        IDLE: begin
          bit_count <= 8'b0;
          data_count <= 8'b0;
        end
        SOF: bit_count <= 8'b0;
        ID: bit_count <= (bit_count < 10) ? bit_count + 1'b1 : 8'b0;
        RTR: bit_count <= 8'b0;
        CONTROL: bit_count <= (bit_count < 5) ? bit_count + 1'b1 : 8'b0;
        DATA: begin
          if (bit_count < 7) begin
            bit_count <= bit_count + 1'b1;
          end else begin
            bit_count <= 8'b0;
            data_count <= data_count + 1'b1;
          end
        end
        CRC: bit_count <= (bit_count < 14) ? bit_count + 1'b1 : 8'b0;
        ACK: bit_count <= 8'b0;
        EOF: bit_count <= (bit_count < 6) ? bit_count + 1'b1 : 8'b0;
        default: begin
          bit_count <= 8'b0;
          data_count <= 8'b0;
        end
      endcase
    end
  end
endmodule

//CRC生成器模块
module crc_generator (
  input clk, reset_n,
  input [3:0] state,
  input [10:0] identifier,
  input [7:0] data_in,
  input [3:0] data_length,
  input [7:0] bit_count,
  output reg [14:0] crc_value
);
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  reg current_bit;
  reg crc_enable;
  
  // 根据当前位和状态确定要处理的比特
  always @(*) begin
    crc_enable = 1'b0;
    current_bit = 1'b0;
    
    case(state)
      ID: begin
        crc_enable = 1'b1;
        current_bit = identifier[10-bit_count];
      end
      RTR: begin
        crc_enable = 1'b1;
        current_bit = 1'b0; // RTR位通常为0表示数据帧
      end
      CONTROL: begin
        crc_enable = 1'b1;
        current_bit = (bit_count < 4) ? data_length[3-bit_count] : 1'b0;
      end
      DATA: begin
        crc_enable = 1'b1;
        current_bit = data_in[7-bit_count];
      end
      default: crc_enable = 1'b0;
    endcase
  end
  
  // CRC计算 - 使用CRC-15多项式 x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + x^0
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      crc_value <= 15'h0;
    end else if (state == IDLE) begin
      crc_value <= 15'h0;
    end else if (crc_enable) begin
      crc_value[0] <= current_bit ^ crc_value[14];
      crc_value[1] <= crc_value[0];
      crc_value[2] <= crc_value[1];
      crc_value[3] <= crc_value[2] ^ (current_bit ^ crc_value[14]);
      crc_value[4] <= crc_value[3] ^ (current_bit ^ crc_value[14]);
      crc_value[5] <= crc_value[4];
      crc_value[6] <= crc_value[5];
      crc_value[7] <= crc_value[6] ^ (current_bit ^ crc_value[14]);
      crc_value[8] <= crc_value[7] ^ (current_bit ^ crc_value[14]);
      crc_value[9] <= crc_value[8];
      crc_value[10] <= crc_value[9] ^ (current_bit ^ crc_value[14]);
      crc_value[11] <= crc_value[10];
      crc_value[12] <= crc_value[11];
      crc_value[13] <= crc_value[12];
      crc_value[14] <= crc_value[13] ^ (current_bit ^ crc_value[14]);
    end
  end
endmodule

//输出控制器模块
module output_controller (
  input clk, reset_n,
  input [3:0] state,
  input [10:0] identifier,
  input [7:0] data_in,
  input [14:0] crc_value,
  input [7:0] bit_count, data_count,
  input [3:0] data_length,
  output reg tx_active, tx_done, can_tx
);
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  
  // 输出控制逻辑
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      can_tx <= 1'b1;    // 总线空闲时保持高电平
      tx_active <= 1'b0;
      tx_done <= 1'b0;
    end else begin
      case(state)
        IDLE: begin
          can_tx <= 1'b1;
          tx_active <= 1'b0;
          tx_done <= 1'b0;
        end
        SOF: begin
          can_tx <= 1'b0;    // 起始帧位为0
          tx_active <= 1'b1;
          tx_done <= 1'b0;
        end
        ID: begin
          can_tx <= identifier[10-bit_count];
          tx_active <= 1'b1;
        end
        RTR: begin
          can_tx <= 1'b0;    // 数据帧RTR=0
          tx_active <= 1'b1;
        end
        CONTROL: begin
          if (bit_count < 4)
            can_tx <= data_length[3-bit_count];
          else
            can_tx <= 1'b0;  // 保留位和IDE位
          tx_active <= 1'b1;
        end
        DATA: begin
          if (data_count < data_length)
            can_tx <= data_in[7-bit_count];
          else
            can_tx <= 1'b0;  // 填充位
          tx_active <= 1'b1;
        end
        CRC: begin
          can_tx <= crc_value[14-bit_count];
          tx_active <= 1'b1;
        end
        ACK: begin
          can_tx <= 1'b1;    // 接收器应当在此处提供ACK位
          tx_active <= 1'b1;
        end
        EOF: begin
          can_tx <= 1'b1;    // 结束帧为7个连续的1
          tx_active <= 1'b1;
          if (bit_count == 6)
            tx_done <= 1'b1;
        end
        default: begin
          can_tx <= 1'b1;
          tx_active <= 1'b0;
          tx_done <= 1'b0;
        end
      endcase
    end
  end
endmodule