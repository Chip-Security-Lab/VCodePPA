//SystemVerilog
module uart_config_stop #(parameter DATA_W = 8) (
  input logic clk, reset_n, tx_start,
  input logic [DATA_W-1:0] tx_data,
  input logic [1:0] stop_bits, // 00:1bit, 01:1.5bits, 10:2bits
  output logic tx, tx_busy
);
  // 状态编码优化 - 使用独热码编码提高可靠性和性能
  localparam [4:0] ST_IDLE  = 5'b00001, 
                   ST_START = 5'b00010, 
                   ST_DATA  = 5'b00100, 
                   ST_STOP1 = 5'b01000, 
                   ST_STOP2 = 5'b10000;
                   
  reg [4:0] state_r;
  reg [DATA_W-1:0] data_r;
  reg [$clog2(DATA_W):0] bit_count; // 使用最小位宽
  reg [1:0] stop_count;
  
  // 优化比较链逻辑
  wire is_data_complete = (bit_count == DATA_W-1);
  wire is_stop_complete = (stop_count == 0);
  wire need_second_stop = |stop_bits; // 任何非零都需要第二个停止位
  
  always_ff @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      state_r <= ST_IDLE;
      data_r <= '0;
      bit_count <= '0;
      stop_count <= '0;
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
          bit_count <= '0; 
        end
        
        ST_DATA: begin
          tx <= data_r[0];
          // 优化移位操作
          data_r <= data_r >> 1;
          
          if (is_data_complete) begin
            state_r <= ST_STOP1;
            // 优化比较逻辑，使用查找表方式确定stop_count
            stop_count <= (stop_bits == 2'b00) ? '0 : 
                         ((stop_bits == 2'b01) ? 2'd1 : 2'd2);
          end else begin
            bit_count <= bit_count + 1'b1;
          end
        end
        
        ST_STOP1: begin
          tx <= 1'b1;
          if (is_stop_complete) begin
            state_r <= ST_IDLE;
            tx_busy <= 1'b0;
          end else begin
            state_r <= ST_STOP2;
            stop_count <= stop_count - 1'b1;
          end
        end
        
        ST_STOP2: begin
          tx <= 1'b1;
          if (is_stop_complete) begin
            state_r <= ST_IDLE;
            tx_busy <= 1'b0;
          end else begin
            stop_count <= stop_count - 1'b1;
          end
        end
        
        default: state_r <= ST_IDLE;
      endcase
    end
endmodule