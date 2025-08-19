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
  reg [2:0] bit_idx_q, bit_idx_d;
  reg [7:0] data_q, data_d;
  reg parity_calc_d, parity_calc_q;

  wire parity_result;

  // Parity calculation module instantiation
  parity_cla #(
    .WIDTH(8)
  ) u_parity_cla (
    .data_in(data_d),
    .parity_type(parity_type[0]),
    .parity_out(parity_result)
  );

  always @(posedge clk) begin
    if (!rst_n) begin
      state_q      <= IDLE;
      bit_idx_q    <= 3'd0;
      data_q       <= 8'd0;
      rx_valid     <= 1'b0;
      parity_err   <= 1'b0;
      parity_calc_q<= 1'b0;
    end else begin
      state_q      <= state_d;
      bit_idx_q    <= bit_idx_d;
      data_q       <= data_d;
      parity_calc_q<= parity_calc_d;

      if (state_q == STOP && state_d == IDLE) begin
        rx_valid   <= 1'b1;
        if (parity_type != 2'b00)
          parity_err <= (parity_calc_q != rx_in);
        else
          parity_err <= 1'b0;
      end else begin
        rx_valid   <= 1'b0;
      end
    end
  end

  always @(*) begin
    state_d       = state_q;
    bit_idx_d     = bit_idx_q;
    data_d        = data_q;
    parity_calc_d = parity_calc_q;

    case (state_q)
      IDLE: begin
        if (rx_in == 1'b0) begin
          state_d = START;
        end
      end
      START: begin
        state_d = DATA;
      end
      DATA: begin
        data_d = {rx_in, data_q[7:1]};
        if (bit_idx_q == 3'd7) begin
          bit_idx_d     = 3'd0;
          state_d       = (parity_type != 2'b00) ? PARITY : STOP;
          parity_calc_d = parity_result;
        end else begin
          bit_idx_d = bit_idx_q + 3'd1;
        end
      end
      PARITY: begin
        state_d = STOP;
      end
      STOP: begin
        state_d = IDLE;
      end
      default: begin
        state_d = IDLE;
      end
    endcase
  end

  always @(posedge clk) begin
    if (state_q == STOP && state_d == IDLE) begin
      rx_data <= data_q;
    end
  end

endmodule

// Parameterized Parity Calculator using Carry Lookahead Adder
module parity_cla #(
  parameter WIDTH = 8
)(
  input  wire [WIDTH-1:0] data_in,
  input  wire             parity_type, // 0: even, 1: odd
  output wire             parity_out
);

  wire [WIDTH-1:0] p;
  wire [WIDTH-1:0] g;
  wire [WIDTH:0]   c;
  wire [WIDTH-1:0] sum;

  assign p = data_in ^ {WIDTH{1'b0}}; // propagate = data_in
  assign g = data_in & {WIDTH{1'b0}}; // generate = 0

  assign c[0] = parity_type;

  genvar i;
  generate
    for (i = 0; i < WIDTH; i = i + 1) begin : gen_carry
      assign c[i+1] = g[i] | (p[i] & c[i]);
    end
  endgenerate

  assign sum = data_in ^ c[WIDTH-1:0];

  assign parity_out = ^sum;

endmodule