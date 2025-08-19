//SystemVerilog
module moore_3state_glitch_filter_pipeline(
  input  clk,
  input  rst,
  input  in,
  input  valid_in,
  output reg ready_out,
  output reg out,
  output reg valid_out
);

  reg [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;

  // Ready signal generation
  always @* begin
    ready_out = 1'b1; // Always ready to accept new data
  end

  // Stage 1: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= STABLE0;
      valid_out <= 1'b0;
    end else if (valid_in) begin
      state_stage1 <= next_state_stage1;
      valid_out <= 1'b1;
    end else begin
      valid_out <= 1'b0;
    end
  end

  // Stage 2: Next State Logic
  always @* begin
    case (state_stage1)
      STABLE0: next_state_stage1 = in ? TRANS : STABLE0;
      TRANS:   next_state_stage1 = in ? STABLE1 : STABLE0;
      STABLE1: next_state_stage1 = in ? STABLE1 : TRANS;
      default: next_state_stage1 = STABLE0;
    endcase
  end

  // Stage 3: State Register for next state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= STABLE0;
    end else if (valid_in) begin
      state_stage2 <= next_state_stage2;
    end
  end

  // Stage 4: Next State Logic for stage 2
  always @* begin
    case (state_stage2)
      STABLE0: next_state_stage2 = in ? TRANS : STABLE0;
      TRANS:   next_state_stage2 = in ? STABLE1 : STABLE0;
      STABLE1: next_state_stage2 = in ? STABLE1 : TRANS;
      default: next_state_stage2 = STABLE0;
    endcase
  end

  // Output Logic
  always @* begin
    out = (state_stage2 == STABLE1);
  end
endmodule