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
  localparam [2:0] IDLE  = 3'd0;
  localparam [2:0] START = 3'd1;
  localparam [2:0] DATA  = 3'd2;
  localparam [2:0] PARITY= 3'd3;
  localparam [2:0] STOP  = 3'd4;

  reg [2:0] state_reg, state_next;
  reg [2:0] bit_index_reg, bit_index_next;
  reg [7:0] data_reg, data_next;
  reg [7:0] data_latch_reg, data_latch_next;
  reg parity_calc_en_reg, parity_calc_en_next;
  wire parity_bit_calc;

  // 优化：分解条件判断链，提前常量表达式，减少关键路径
  wire parity_enable = (parity_type != 2'b00);
  wire is_odd_parity = parity_type[0];

  // 并行前缀奇偶校验
  parallel_prefix_parity_8 u_parity (
    .data_in(data_latch_reg),
    .odd_even(is_odd_parity),
    .parity_out(parity_bit_calc)
  );

  // 优化：同步数据、状态寄存器，分解长判断链
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state_reg       <= IDLE;
      bit_index_reg   <= 3'd0;
      data_reg        <= 8'd0;
      data_latch_reg  <= 8'd0;
      parity_calc_en_reg <= 1'b0;
      rx_valid        <= 1'b0;
      rx_data         <= 8'd0;
      parity_err      <= 1'b0;
    end else begin
      state_reg         <= state_next;
      bit_index_reg     <= bit_index_next;
      data_reg          <= data_next;
      data_latch_reg    <= data_latch_next;
      parity_calc_en_reg<= parity_calc_en_next;

      // 优化：解耦判断，避免串行条件链
      rx_valid <= (state_reg == STOP) && (state_next == IDLE);

      if ((state_reg == STOP) && (state_next == IDLE)) begin
        rx_data <= data_reg;
        if (parity_enable) begin
          parity_err <= (parity_bit_calc != rx_in);
        end else begin
          parity_err <= 1'b0;
        end
      end else begin
        // 保持上一个值
        parity_err <= parity_err;
        rx_data <= rx_data;
      end
    end
  end

  // 优化：平衡条件链，减少关键路径
  always @(*) begin
    // 默认保持当前值
    state_next        = state_reg;
    bit_index_next    = bit_index_reg;
    data_next         = data_reg;
    data_latch_next   = data_latch_reg;
    parity_calc_en_next = 1'b0;

    case (state_reg)
      IDLE: begin
        if (rx_in == 1'b0)
          state_next = START;
      end
      START: begin
        state_next = DATA;
      end
      DATA: begin
        data_next = {rx_in, data_reg[7:1]};
        if (bit_index_reg == 3'd7) begin
          bit_index_next = 3'd0;
          if (parity_enable)
            state_next = PARITY;
          else
            state_next = STOP;
          parity_calc_en_next = 1'b1;
          data_latch_next = {rx_in, data_reg[7:1]};
        end else begin
          bit_index_next = bit_index_reg + 3'd1;
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
  end

endmodule

module parallel_prefix_parity_8 (
  input  wire [7:0] data_in,
  input  wire odd_even, // 1: odd, 0: even
  output wire parity_out
);
  // 优化：平衡XOR树，减少串行XOR级数
  wire [7:0] p;
  wire xor01, xor23, xor45, xor67;
  wire xor0123, xor4567;
  assign p = data_in;

  // Balanced XOR tree for parity
  assign xor01   = p[0] ^ p[1];
  assign xor23   = p[2] ^ p[3];
  assign xor45   = p[4] ^ p[5];
  assign xor67   = p[6] ^ p[7];

  assign xor0123 = xor01 ^ xor23;
  assign xor4567 = xor45 ^ xor67;

  assign parity_out = xor0123 ^ xor4567 ^ odd_even;

endmodule