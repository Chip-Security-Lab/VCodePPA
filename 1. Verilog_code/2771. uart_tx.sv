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
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_r <= IDLE;
      bit_cnt_r <= 0;
      data_r <= 0;
      tx_line <= 1'b1;
      tx_busy <= 1'b0;
      tx_done <= 1'b0;
    end else begin
      case (state_r)
        IDLE: if (tx_start) begin state_r <= START; data_r <= tx_data; tx_busy <= 1'b1; tx_done <= 1'b0; end
        START: begin tx_line <= 1'b0; state_r <= DATA; bit_cnt_r <= 0; end
        DATA: begin 
          tx_line <= data_r[0];
          data_r <= {1'b0, data_r[DWIDTH-1:1]};
          bit_cnt_r <= bit_cnt_r + 1'b1;
          if (bit_cnt_r == DWIDTH-1) state_r <= STOP;
        end
        STOP: begin tx_line <= 1'b1; state_r <= IDLE; tx_busy <= 1'b0; tx_done <= 1'b1; end
      endcase
    end
  end
endmodule