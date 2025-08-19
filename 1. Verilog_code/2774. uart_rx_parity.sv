module uart_rx_parity (
  input wire clk, rst_n, rx_in,
  input wire [1:0] parity_type, // 00:none, 01:odd, 10:even
  output reg [7:0] rx_data,
  output reg rx_valid, parity_err
);
  localparam IDLE = 3'd0, START = 3'd1, DATA = 3'd2, PARITY = 3'd3, STOP = 3'd4;
  reg [2:0] state_q, state_d;
  reg [2:0] bit_idx_q, bit_idx_d;
  reg [7:0] data_q, data_d;
  reg calc_parity;
  
  always @(posedge clk) begin
    if (!rst_n) begin
      state_q <= IDLE;
      bit_idx_q <= 0;
      data_q <= 0;
      rx_valid <= 0;
      parity_err <= 0;
    end else begin
      state_q <= state_d;
      bit_idx_q <= bit_idx_d;
      data_q <= data_d;
      
      if (state_q == STOP && state_d == IDLE) begin
        rx_valid <= 1;
        if (parity_type != 2'b00) parity_err <= (calc_parity != rx_in);
      end else begin
        rx_valid <= 0;
      end
    end
  end
  
  always @(*) begin
    state_d = state_q;
    bit_idx_d = bit_idx_q;
    data_d = data_q;
    
    case (state_q)
      IDLE: if (rx_in == 0) state_d = START;
      START: state_d = DATA;
      DATA: begin
        data_d = {rx_in, data_q[7:1]};
        if (bit_idx_q == 7) begin
          bit_idx_d = 0;
          state_d = (parity_type != 2'b00) ? PARITY : STOP;
          calc_parity = ^data_d ^ parity_type[0];
        end else bit_idx_d = bit_idx_q + 1;
      end
      PARITY: state_d = STOP;
      STOP: state_d = IDLE;
    endcase
  end
  
  always @(posedge clk) if (state_q == STOP && state_d == IDLE) rx_data <= data_q;
endmodule