//SystemVerilog
module pipeline_arbiter(
  input wire clk, async_reset_n,
  input wire [3:0] request,
  input wire pipe_ready,
  output reg [3:0] grant,
  output reg valid
);

  // Pipeline stage registers
  reg [3:0] req_stage1, req_stage2, req_stage3, req_stage4, req_stage5;
  reg [1:0] state, next_state;
  reg [1:0] state_stage1, state_stage2, state_stage3;
  reg pipe_ready_stage1, pipe_ready_stage2, pipe_ready_stage3;
  reg [3:0] grant_stage1, grant_stage2, grant_stage3;
  reg valid_stage1, valid_stage2, valid_stage3;

  // Buffer registers for high fanout signals
  reg [1:0] next_state_buf1, next_state_buf2, next_state_buf3;
  reg [3:0] req_stage2_buf1, req_stage2_buf2, req_stage2_buf3;
  reg [1:0] state_stage1_buf1, state_stage1_buf2, state_stage1_buf3;
  reg [1:0] b00_buf1, b00_buf2, b00_buf3;
  reg [1:0] b0_buf1, b0_buf2, b0_buf3;

  // Arbitration logic
  always @(*) begin
    case(state)
      2'b00: next_state = (request != 4'b0) ? 2'b01 : 2'b00;
      2'b01: next_state = (pipe_ready) ? 2'b10 : 2'b01;
      2'b10: next_state = 2'b11;
      2'b11: next_state = 2'b00;
      default: next_state = 2'b00;
    endcase
  end

  // Main pipeline with buffered signals
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      state <= 2'b00;
      state_stage1 <= 2'b00;
      state_stage2 <= 2'b00;
      state_stage3 <= 2'b00;
      req_stage1 <= 4'b0;
      req_stage2 <= 4'b0;
      req_stage3 <= 4'b0;
      req_stage4 <= 4'b0;
      req_stage5 <= 4'b0;
      pipe_ready_stage1 <= 1'b0;
      pipe_ready_stage2 <= 1'b0;
      pipe_ready_stage3 <= 1'b0;
      grant_stage1 <= 4'b0;
      grant_stage2 <= 4'b0;
      grant_stage3 <= 4'b0;
      grant <= 4'b0;
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid_stage3 <= 1'b0;
      valid <= 1'b0;
      next_state_buf1 <= 2'b00;
      next_state_buf2 <= 2'b00;
      next_state_buf3 <= 2'b00;
      req_stage2_buf1 <= 4'b0;
      req_stage2_buf2 <= 4'b0;
      req_stage2_buf3 <= 4'b0;
      state_stage1_buf1 <= 2'b00;
      state_stage1_buf2 <= 2'b00;
      state_stage1_buf3 <= 2'b00;
      b00_buf1 <= 2'b00;
      b00_buf2 <= 2'b00;
      b00_buf3 <= 2'b00;
      b0_buf1 <= 2'b00;
      b0_buf2 <= 2'b00;
      b0_buf3 <= 2'b00;
    end else begin
      // Stage 1: Request and state capture with buffering
      next_state_buf1 <= next_state;
      next_state_buf2 <= next_state_buf1;
      next_state_buf3 <= next_state_buf2;
      state <= next_state_buf3;
      req_stage1 <= request;
      pipe_ready_stage1 <= pipe_ready;

      // Stage 2: Request processing with buffering
      state_stage1_buf1 <= state;
      state_stage1_buf2 <= state_stage1_buf1;
      state_stage1_buf3 <= state_stage1_buf2;
      state_stage1 <= state_stage1_buf3;
      req_stage2_buf1 <= req_stage1;
      req_stage2_buf2 <= req_stage2_buf1;
      req_stage2_buf3 <= req_stage2_buf2;
      req_stage2 <= req_stage2_buf3;
      pipe_ready_stage2 <= pipe_ready_stage1;

      // Stage 3: Grant generation with buffering
      state_stage2 <= state_stage1;
      req_stage3 <= req_stage2;
      pipe_ready_stage3 <= pipe_ready_stage2;
      case(state_stage1)
        2'b01: grant_stage1 <= req_stage2;
        2'b10: grant_stage1 <= req_stage2;
        default: grant_stage1 <= 4'b0;
      endcase

      // Stage 4: Grant processing
      state_stage3 <= state_stage2;
      req_stage4 <= req_stage3;
      grant_stage2 <= grant_stage1;
      valid_stage1 <= (state_stage1 == 2'b01 || state_stage1 == 2'b10);

      // Stage 5: Grant and valid signal processing
      req_stage5 <= req_stage4;
      grant_stage3 <= grant_stage2;
      valid_stage2 <= valid_stage1;

      // Stage 6: Final output
      grant <= grant_stage3;
      valid <= valid_stage2;
    end
  end

endmodule