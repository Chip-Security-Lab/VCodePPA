//SystemVerilog
module uart_tx #(parameter DWIDTH = 8, CLK_DIV = 16) (
  input wire clk, rst_n, tx_start,
  input wire [DWIDTH-1:0] tx_data,
  output reg tx_busy, tx_done,
  output reg tx_line
);
  // FSM状态定义
  localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
  
  // 内部寄存器
  reg [1:0] state_r, state_next;
  reg [3:0] bit_cnt_r, bit_cnt_next;
  reg [DWIDTH-1:0] data_r, data_next;
  reg tx_line_next, tx_busy_next, tx_done_next;
  
  // 状态寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r <= IDLE;
    end else begin
      state_r <= state_next;
    end
  end
  
  // 数据寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_r <= 0;
      bit_cnt_r <= 0;
    end else begin
      data_r <= data_next;
      bit_cnt_r <= bit_cnt_next;
    end
  end
  
  // 输出寄存器更新
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_line <= 1'b1;
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
    end else begin
      tx_line <= tx_line_next;
      tx_busy <= tx_busy_next;
      tx_done <= tx_done_next;
    end
  end
  
  // 下一状态和控制信号逻辑
  always @(*) begin
    // 默认保持当前值
    state_next = state_r;
    data_next = data_r;
    bit_cnt_next = bit_cnt_r;
    tx_line_next = tx_line;
    tx_busy_next = tx_busy;
    tx_done_next = tx_done;
    
    case (state_r)
      IDLE: begin
        tx_line_next = 1'b1;
        if (tx_start) begin
          state_next = START;
          data_next = tx_data;
          tx_busy_next = 1'b1;
          tx_done_next = 1'b0;
        end
      end
      
      START: begin
        tx_line_next = 1'b0;
        state_next = DATA;
        bit_cnt_next = 0;
      end
      
      DATA: begin
        tx_line_next = data_r[0];
        data_next = {1'b0, data_r[DWIDTH-1:1]};
        bit_cnt_next = bit_cnt_r + 1'b1;
        
        if (bit_cnt_r == DWIDTH-1) begin
          state_next = STOP;
        end
      end
      
      STOP: begin
        tx_line_next = 1'b1;
        state_next = IDLE;
        tx_busy_next = 1'b0;
        tx_done_next = 1'b1;
      end
    endcase
  end
  
endmodule