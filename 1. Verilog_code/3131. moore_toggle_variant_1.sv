//SystemVerilog
module moore_toggle(
  input  clk,
  input  rst,
  input  en,
  output reg out
);
  // Pipeline stage registers
  reg state_stage1, next_state_stage1;
  reg state_stage2, next_state_stage2;
  reg en_stage1, en_stage2;
  reg valid_stage1, valid_stage2;

  // Constants
  localparam S0 = 1'b0,
             S1 = 1'b1;

  // Stage 1: State update and next-state logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= S0;
      en_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end
    else begin
      state_stage1 <= next_state_stage1;
      en_stage1 <= en;
      valid_stage1 <= 1'b1;
    end
  end

  // Next-state logic for stage 1
  always @* begin
    next_state_stage1 = state_stage1;
    if (en_stage1) begin
      case (state_stage1)
        S0: next_state_stage1 = S1;
        S1: next_state_stage1 = S0;
      endcase
    end
  end

  // Stage 2: Output generation and result propagation
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= S0;
      en_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
      out <= 1'b0;
    end
    else begin
      state_stage2 <= state_stage1;
      en_stage2 <= en_stage1;
      valid_stage2 <= valid_stage1;

      // Moore output generation
      if (valid_stage1)
        out <= (state_stage1 == S1);
    end
  end

  // Next-state logic propagation to stage 2
  always @* begin
    next_state_stage2 = state_stage2;
    if (en_stage2) begin
      case (state_stage2)
        S0: next_state_stage2 = S1;
        S1: next_state_stage2 = S0;
      endcase
    end
  end

  // Wallace Tree Multiplier for 8-bit inputs
  wire [15:0] product;
  reg [7:0] a, b;
  
  // Wallace tree multiplication logic
  wire [7:0] partial_products[7:0];
  generate
    genvar i, j;
    for (i = 0; i < 8; i = i + 1) begin: pp_gen
      assign partial_products[i] = a & {8{b[i]}};
    end
  endgenerate

  wire [15:0] sum1, sum2;
  wire [7:0] carry1, carry2;

  // First reduction stage
  assign {carry1, sum1} = partial_products[0] + partial_products[1];
  assign {carry2, sum2} = partial_products[2] + partial_products[3];
  assign product = sum1 + sum2 + partial_products[4] + partial_products[5] + partial_products[6] + partial_products[7];

endmodule