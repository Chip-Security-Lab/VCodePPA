//SystemVerilog
module moore_3state_handshake_pipeline(
  input  clk,
  input  rst,
  input  start,
  input  ack,
  input  [1:0] a,
  input  [1:0] b,
  output reg done,
  output reg [3:0] product
);

  reg [1:0] state_stage1, state_stage2, state_stage3, next_state_stage1, next_state_stage2, next_state_stage3;
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;

  // Baugh-Wooley multiplier signals
  wire [3:0] partial_products [3:0];
  wire [3:0] sum_stage1;
  wire [3:0] sum_stage2;
  wire [3:0] sum_stage3;
  reg  [3:0] product_reg;

  // Generate partial products
  assign partial_products[0] = {2'b00, a[0] & b[0]};
  assign partial_products[1] = {1'b0, a[0] & b[1], 1'b0};
  assign partial_products[2] = {1'b0, a[1] & b[0], 1'b0};
  assign partial_products[3] = {a[1] & b[1], 2'b00};

  // First stage addition
  assign sum_stage1 = partial_products[0] + partial_products[1];
  assign sum_stage2 = sum_stage1 + partial_products[2];
  assign sum_stage3 = sum_stage2 + partial_products[3];

  // Pipeline register for state and product
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      state_stage2 <= IDLE;
      state_stage3 <= IDLE;
      product_reg <= 4'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      state_stage2 <= state_stage1;
      state_stage3 <= state_stage2;
      product_reg <= sum_stage3;
    end
  end

  // Next state logic
  always @* begin
    case (state_stage1)
      IDLE:      next_state_stage1 = start ? WAIT_ACK : IDLE;
      WAIT_ACK:  next_state_stage1 = ack   ? COMPLETE : WAIT_ACK;
      COMPLETE:  next_state_stage1 = IDLE;
      default:   next_state_stage1 = IDLE;
    endcase
  end

  // Next state logic for stage 2
  always @* begin
    case (state_stage2)
      IDLE:      next_state_stage2 = start ? WAIT_ACK : IDLE;
      WAIT_ACK:  next_state_stage2 = ack   ? COMPLETE : WAIT_ACK;
      COMPLETE:  next_state_stage2 = IDLE;
      default:   next_state_stage2 = IDLE;
    endcase
  end

  // Next state logic for stage 3
  always @* begin
    case (state_stage3)
      IDLE:      next_state_stage3 = start ? WAIT_ACK : IDLE;
      WAIT_ACK:  next_state_stage3 = ack   ? COMPLETE : WAIT_ACK;
      COMPLETE:  next_state_stage3 = IDLE;
      default:   next_state_stage3 = IDLE;
    endcase
  end

  // Output logic
  always @* begin
    done = (state_stage3 == COMPLETE);
    product = product_reg;
  end
endmodule