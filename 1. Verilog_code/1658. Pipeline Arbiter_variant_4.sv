//SystemVerilog
module pipeline_arbiter(
  input wire clk, async_reset_n,
  input wire [3:0] request,
  input wire pipe_ready,
  output reg [3:0] grant,
  output reg valid
);

  // Pipeline stage registers
  reg [3:0] req_stage1, req_stage2, req_stage3;
  reg [1:0] state, next_state;
  reg [1:0] state_stage1, state_stage2;
  reg pipe_ready_stage1, pipe_ready_stage2;
  reg [3:0] grant_stage1, grant_stage2;
  reg valid_stage1, valid_stage2;

  // Arbitration logic
  always @(*) begin
    if (state == 2'b00) begin
      if (|request)
        next_state = 2'b01;
      else
        next_state = 2'b00;
    end
    else if (state == 2'b01) begin
      if (pipe_ready)
        next_state = 2'b10;
      else
        next_state = 2'b01;
    end
    else if (state == 2'b10)
      next_state = 2'b11;
    else if (state == 2'b11)
      next_state = 2'b00;
    else
      next_state = 2'b00;
  end

  // Pipeline stages
  always @(posedge clk or negedge async_reset_n) begin
    if (!async_reset_n) begin
      state <= 2'b00;
      state_stage1 <= 2'b00;
      state_stage2 <= 2'b00;
      req_stage1 <= 4'b0;
      req_stage2 <= 4'b0;
      req_stage3 <= 4'b0;
      pipe_ready_stage1 <= 1'b0;
      pipe_ready_stage2 <= 1'b0;
      grant_stage1 <= 4'b0;
      grant_stage2 <= 4'b0;
      grant <= 4'b0;
      valid_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
      valid <= 1'b0;
    end else begin
      // Stage 1: Request capture and state update
      state <= next_state;
      req_stage1 <= request;
      pipe_ready_stage1 <= pipe_ready;
      state_stage1 <= state;

      // Stage 2: Arbitration computation
      req_stage2 <= req_stage1;
      pipe_ready_stage2 <= pipe_ready_stage1;
      state_stage2 <= state_stage1;
      if (state_stage1 == 2'b01) begin
        grant_stage1 <= req_stage1;
        valid_stage1 <= 1'b1;
      end else begin
        grant_stage1 <= 4'b0;
        valid_stage1 <= 1'b0;
      end

      // Stage 3: Grant and valid output
      req_stage3 <= req_stage2;
      grant_stage2 <= grant_stage1;
      valid_stage2 <= valid_stage1;
      grant <= grant_stage2;
      valid <= valid_stage2;
    end
  end
endmodule