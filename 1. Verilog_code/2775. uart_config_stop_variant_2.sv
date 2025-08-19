//SystemVerilog
module uart_config_stop #(parameter DATA_W = 8) (
  input clk, reset_n, tx_start,
  input [DATA_W-1:0] tx_data,
  input [1:0] stop_bits, // 00:1bit, 01:1.5bits, 10:2bits
  output reg tx, tx_busy
);
  // 改为参数定义状态
  parameter ST_IDLE = 0, ST_START = 1, ST_DATA = 2, ST_STOP1 = 3, ST_STOP2 = 4;
  
  reg [2:0] state_r, next_state;
  reg [DATA_W-1:0] data_r, next_data;
  reg [3:0] bit_count, next_bit_count;
  reg [1:0] stop_count, next_stop_count;
  reg next_tx, next_tx_busy;
  
  // 使用补码加法实现减法
  wire [3:0] stop_count_minus_one;
  assign stop_count_minus_one = {2'b00, stop_count} + 4'b1111; // 加上-1的补码表示
  
  // 状态寄存器更新
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state_r <= ST_IDLE;
      data_r <= 0;
      bit_count <= 0;
      stop_count <= 0;
      tx <= 1'b1;
      tx_busy <= 1'b0;
    end else begin
      state_r <= next_state;
      data_r <= next_data;
      bit_count <= next_bit_count;
      stop_count <= next_stop_count;
      tx <= next_tx;
      tx_busy <= next_tx_busy;
    end
  end
  
  // 下一状态逻辑
  always @(*) begin
    next_state = state_r;
    next_data = data_r;
    next_bit_count = bit_count;
    next_stop_count = stop_count;
    next_tx = tx;
    next_tx_busy = tx_busy;
    
    case (state_r)
      ST_IDLE: begin
        next_tx = 1'b1;
        if (tx_start) begin
          next_state = ST_START;
          next_data = tx_data;
          next_tx_busy = 1'b1;
        end
      end
      
      ST_START: begin 
        next_tx = 1'b0; 
        next_state = ST_DATA; 
        next_bit_count = 0; 
      end
      
      ST_DATA: begin
        next_tx = data_r[0];
        next_data = {1'b0, data_r[DATA_W-1:1]};
        if (bit_count == DATA_W-1) begin
          next_state = ST_STOP1;
          next_stop_count = (stop_bits == 2'b00) ? 0 : 
                           ((stop_bits == 2'b01) ? 1 : 2);
        end else 
          next_bit_count = bit_count + 1'b1;
      end
      
      ST_STOP1: begin
        next_tx = 1'b1;
        if (stop_count == 0) begin
          next_state = ST_IDLE;
          next_tx_busy = 1'b0;
        end else begin
          next_state = ST_STOP2;
          next_stop_count = stop_count_minus_one[1:0];
        end
      end
      
      ST_STOP2: begin
        next_tx = 1'b1;
        if (stop_count == 0) begin
          next_state = ST_IDLE;
          next_tx_busy = 1'b0;
        end else 
          next_stop_count = stop_count_minus_one[1:0];
      end
      
      default: next_state = ST_IDLE;
    endcase
  end
  
endmodule