//SystemVerilog
module uart_tx #(parameter DWIDTH = 8, CLK_DIV = 16) (
  input wire clk, rst_n, tx_start,
  input wire [DWIDTH-1:0] tx_data,
  output reg tx_busy, tx_done,
  output reg tx_line
);
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  reg [1:0] state_r, state_next;
  reg [3:0] bit_cnt_r;
  reg [DWIDTH-1:0] data_r;
  
  // 使用二进制补码减法算法
  reg [3:0] bit_remaining;  // 剩余位计数器
  wire [3:0] bit_remaining_next;  // 下一个计数值
  wire [3:0] one_complement;      // 一的补码
  wire [3:0] two_complement;      // 二的补码
  wire carry;                     // 进位标志
  
  // 生成减数"1"的二进制补码
  assign one_complement = ~4'b0001;  // 对"1"取反
  assign {carry, two_complement} = one_complement + 4'b0001;  // 加1获得二进制补码
  
  // 补码减法: bit_remaining - 1
  assign bit_remaining_next = bit_remaining + two_complement;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r <= IDLE;
      bit_cnt_r <= 0;
      bit_remaining <= 0;
      data_r <= 0;
      tx_line <= 1'b1;
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
    end else begin
      case (state_r)
        IDLE: begin
          if (tx_start) begin 
            state_r <= START; 
            data_r <= tx_data; 
            tx_busy <= 1'b1; 
            tx_done <= 1'b0; 
            bit_remaining <= DWIDTH;  // 初始化位计数
          end
        end
        
        START: begin 
          tx_line <= 1'b0; 
          state_r <= DATA; 
          bit_cnt_r <= 0; 
        end
        
        DATA: begin 
          tx_line <= data_r[0];
          data_r <= {1'b0, data_r[DWIDTH-1:1]};
          bit_cnt_r <= bit_cnt_r + 1'b1;
          
          // 使用二进制补码减法
          bit_remaining <= bit_remaining_next;
          
          // 当剩余位为1时，下一位就是最后一位
          if (bit_remaining == 4'b0001) begin
            state_r <= STOP;
          end
        end
        
        STOP: begin 
          tx_line <= 1'b1; 
          state_r <= IDLE; 
          tx_busy <= 1'b0; 
          tx_done <= 1'b1; 
        end
      endcase
    end
  end
endmodule