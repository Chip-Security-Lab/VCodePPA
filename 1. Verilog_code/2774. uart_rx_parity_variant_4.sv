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
  localparam IDLE   = 3'd0,
             START  = 3'd1,
             DATA   = 3'd2,
             PARITY = 3'd3,
             STOP   = 3'd4;

  reg [2:0] state_reg, state_next;
  reg [2:0] bit_idx_reg, bit_idx_next;
  reg [7:0] data_reg, data_next;

  // Pipeline registers for parity calculation
  reg pipeline_calc_parity;
  reg pipeline_parity_bit;
  reg pipeline_parity_check;

  reg [7:0] pipeline_data;
  reg [1:0] pipeline_parity_type;

  // Pipeline register for rx_in at STOP state for parity check alignment
  reg pipeline_rx_in_stop;

  // Control signals
  reg rx_valid_next;
  reg parity_err_next;

  // Optimized parity enable signal
  wire parity_enable;
  assign parity_enable = (|parity_type);

  // Optimized parity calculation
  wire parity_bit_odd;
  wire parity_bit_even;
  assign parity_bit_odd  = ^{rx_in, data_reg[7:1]};
  assign parity_bit_even = ~parity_bit_odd;

  // State register update
  always @(posedge clk) begin
    if (!rst_n) begin
      state_reg <= IDLE;
      bit_idx_reg <= 3'd0;
      data_reg <= 8'd0;
      rx_valid <= 1'b0;
      parity_err <= 1'b0;
      pipeline_calc_parity <= 1'b0;
      pipeline_parity_bit <= 1'b0;
      pipeline_parity_check <= 1'b0;
      pipeline_data <= 8'd0;
      pipeline_parity_type <= 2'd0;
      pipeline_rx_in_stop <= 1'b0;
      rx_data <= 8'd0;
    end else begin
      state_reg <= state_next;
      bit_idx_reg <= bit_idx_next;
      data_reg <= data_next;

      // Capture data and parity info at DATA->PARITY/STOP transition
      if (state_reg == DATA && bit_idx_reg == 3'd7) begin
        pipeline_data <= {rx_in, data_reg[7:1]};
        pipeline_parity_type <= parity_type;
        if (parity_type[1]) begin
          pipeline_calc_parity <= parity_bit_even;
        end else begin
          pipeline_calc_parity <= parity_bit_odd;
        end
      end

      // Latch parity bit at PARITY state
      if (state_reg == PARITY) begin
        pipeline_parity_bit <= rx_in;
      end

      // Latch parity check enable at PARITY or at DATA->STOP transition
      if (state_reg == PARITY || (state_reg == DATA && bit_idx_reg == 3'd7 && parity_enable)) begin
        pipeline_parity_check <= parity_enable;
      end

      // Latch rx_in at STOP for parity check
      if (state_reg == STOP) begin
        pipeline_rx_in_stop <= rx_in;
      end

      // Output valid and error are aligned to STOP->IDLE transition
      rx_valid <= rx_valid_next;
      parity_err <= parity_err_next;

      // Output data at STOP->IDLE
      if (state_reg == STOP && state_next == IDLE) begin
        rx_data <= data_reg;
      end
    end
  end

  // Next-state logic and combinational outputs
  always @(*) begin
    state_next = state_reg;
    bit_idx_next = bit_idx_reg;
    data_next = data_reg;
    rx_valid_next = 1'b0;
    parity_err_next = parity_err;

    case (state_reg)
      IDLE: begin
        if (~rx_in)
          state_next = START;
      end
      START: begin
        state_next = DATA;
      end
      DATA: begin
        data_next = {rx_in, data_reg[7:1]};
        if (bit_idx_reg == 3'd7) begin
          bit_idx_next = 3'd0;
          if (parity_enable) begin
            state_next = PARITY;
          end else begin
            state_next = STOP;
          end
        end else begin
          bit_idx_next = bit_idx_reg + 3'd1;
        end
      end
      PARITY: begin
        state_next = STOP;
      end
      STOP: begin
        state_next = IDLE;
      end
      default: begin
        state_next = IDLE;
      end
    endcase

    // Output valid and error at STOP->IDLE
    if (state_reg == STOP && state_next == IDLE) begin
      rx_valid_next = 1'b1;
      if (pipeline_parity_check) begin
        if (pipeline_calc_parity != pipeline_parity_bit) begin
          parity_err_next = 1'b1;
        end else begin
          parity_err_next = 1'b0;
        end
      end else begin
        parity_err_next = 1'b0;
      end
    end
  end

endmodule