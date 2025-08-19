//SystemVerilog
module uart_rx_parity (
  input wire clk,
  input wire rst_n,
  input wire rx_in,
  input wire [1:0] parity_type, // 00:none, 01:odd, 10:even
  output reg [7:0] rx_data,
  output reg rx_valid,
  output reg parity_err
);

  localparam IDLE  = 3'd0,
             START = 3'd1,
             DATA  = 3'd2,
             PARITY= 3'd3,
             STOP  = 3'd4;

  reg [2:0] state_q, state_d;
  reg [2:0] bit_index_q, bit_index_d;
  reg [7:0] data_q, data_d;
  reg [7:0] data_latched;
  reg parity_calc_q, parity_calc_d;
  reg rx_valid_q, rx_valid_d;
  reg parity_err_q, parity_err_d;

  // Output pipeline register
  always @(posedge clk) begin
    if (!rst_n) begin
      state_q        <= IDLE;
      bit_index_q    <= 3'd0;
      data_q         <= 8'd0;
      data_latched   <= 8'd0;
      parity_calc_q  <= 1'b0;
      rx_valid_q     <= 1'b0;
      parity_err_q   <= 1'b0;
    end else begin
      state_q        <= state_d;
      bit_index_q    <= bit_index_d;
      data_q         <= data_d;
      data_latched   <= data_q;
      parity_calc_q  <= parity_calc_d;
      rx_valid_q     <= rx_valid_d;
      parity_err_q   <= parity_err_d;
    end
  end

  // Optimized combinational logic
  always @(*) begin
    state_d        = state_q;
    bit_index_d    = bit_index_q;
    data_d         = data_q;
    parity_calc_d  = parity_calc_q;
    rx_valid_d     = 1'b0;
    parity_err_d   = parity_err_q;

    case (state_q)
      IDLE: begin
        if (~rx_in)
          state_d = START;
      end

      START: begin
        state_d = DATA;
      end

      DATA: begin
        data_d = {rx_in, data_q[7:1]};
        if (bit_index_q == 3'd7) begin
          bit_index_d = 3'd0;
          // Use range check for parity_type
          if (parity_type[1] | parity_type[0])
            state_d = PARITY;
          else
            state_d = STOP;
          // Efficient parity calculation (XOR reduction)
          parity_calc_d = (^({rx_in, data_q[7:1]}) ^ parity_type[0]);
        end else begin
          bit_index_d = bit_index_q + 3'd1;
        end
      end

      PARITY: begin
        state_d = STOP;
      end

      STOP: begin
        state_d    = IDLE;
        rx_valid_d = 1'b1;
        // Optimized parity error logic using range check
        if (parity_type[1] | parity_type[0])
          parity_err_d = (parity_calc_q != rx_in);
        else
          parity_err_d = 1'b0;
      end

      default: begin
        state_d     = IDLE;
        bit_index_d = 3'd0;
        data_d      = 8'd0;
        parity_calc_d = 1'b0;
        rx_valid_d  = 1'b0;
        parity_err_d= 1'b0;
      end
    endcase
  end

  // Output retiming and pipelining
  always @(posedge clk) begin
    if (!rst_n) begin
      rx_data    <= 8'd0;
      rx_valid   <= 1'b0;
      parity_err <= 1'b0;
    end else begin
      rx_data    <= data_latched;
      rx_valid   <= rx_valid_q;
      parity_err <= parity_err_q;
    end
  end

endmodule