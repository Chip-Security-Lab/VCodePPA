//SystemVerilog
module uart_config_stop #(parameter DATA_W = 8) (
  input clk, reset_n, tx_start,
  input [DATA_W-1:0] tx_data,
  input [1:0] stop_bits, // 00:1bit, 01:1.5bits, 10:2bits
  output reg tx, tx_busy
);
  // 改为参数定义状态
  parameter ST_IDLE = 0, ST_START = 1, ST_DATA = 2, ST_STOP1 = 3, ST_STOP2 = 4;
  reg [2:0] state_r;
  reg [DATA_W-1:0] data_r;
  reg [3:0] bit_count;
  reg [1:0] stop_count;
  
  // 先行借位减法器信号
  wire [3:0] minuend, subtrahend, difference;
  wire [4:0] borrow;
  
  // 先行借位减法器逻辑
  assign minuend = {2'b00, stop_count};
  assign subtrahend = 4'b0001; // 减数固定为1
  assign borrow[0] = 1'b0;
  
  // 计算每位的借位
  assign borrow[1] = (minuend[0] < subtrahend[0]) ? 1'b1 : 1'b0;
  assign borrow[2] = ((minuend[1] < subtrahend[1]) || ((minuend[1] == subtrahend[1]) && borrow[1])) ? 1'b1 : 1'b0;
  assign borrow[3] = ((minuend[2] < subtrahend[2]) || ((minuend[2] == subtrahend[2]) && borrow[2])) ? 1'b1 : 1'b0;
  assign borrow[4] = ((minuend[3] < subtrahend[3]) || ((minuend[3] == subtrahend[3]) && borrow[3])) ? 1'b1 : 1'b0;
  
  // 计算差值
  assign difference[0] = minuend[0] ^ subtrahend[0] ^ borrow[0];
  assign difference[1] = minuend[1] ^ subtrahend[1] ^ borrow[1];
  assign difference[2] = minuend[2] ^ subtrahend[2] ^ borrow[2];
  assign difference[3] = minuend[3] ^ subtrahend[3] ^ borrow[3];
  
  // 结果为0的检测
  wire is_zero = (difference == 4'b0000);
  
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      state_r <= ST_IDLE;
      data_r <= 0;
      bit_count <= 0;
      stop_count <= 0;
      tx <= 1'b1;
      tx_busy <= 1'b0;
    end else begin
      case (state_r)
        ST_IDLE: begin
          tx <= 1'b1;
          if (tx_start) begin
            state_r <= ST_START;
            data_r <= tx_data;
            tx_busy <= 1'b1;
          end
        end
        ST_START: begin 
          tx <= 1'b0; 
          state_r <= ST_DATA; 
          bit_count <= 0; 
        end
        ST_DATA: begin
          tx <= data_r[0];
          data_r <= {1'b0, data_r[DATA_W-1:1]};
          if (bit_count == DATA_W-1) begin
            state_r <= ST_STOP1;
            stop_count <= (stop_bits == 2'b00) ? 0 : ((stop_bits == 2'b01) ? 1 : 2);
          end else bit_count <= bit_count + 1'b1;
        end
        ST_STOP1: begin
          tx <= 1'b1;
          if (is_zero) begin
            state_r <= ST_IDLE;
            tx_busy <= 1'b0;
          end else begin
            state_r <= ST_STOP2;
            stop_count <= difference[1:0];
          end
        end
        ST_STOP2: begin
          tx <= 1'b1;
          if (is_zero) begin
            state_r <= ST_IDLE;
            tx_busy <= 1'b0;
          end else stop_count <= difference[1:0];
        end
        default: state_r <= ST_IDLE;
      endcase
    end
endmodule