//SystemVerilog
module fsm_arbiter_pipelined(
  input wire clock, resetn,
  input wire [3:0] request,
  output reg [3:0] grant
);

  localparam IDLE = 2'b00, GRANT0 = 2'b01, 
             GRANT1 = 2'b10, GRANT2 = 2'b11;
  
  // Pipeline stage 1 registers
  reg [1:0] state_stage1, next_state_stage1;
  reg [3:0] request_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 registers
  reg [1:0] state_stage2;
  reg [3:0] request_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers
  reg [1:0] state_stage3;
  reg [3:0] grant_stage3;
  reg valid_stage3;

  // Stage 1: Request sampling and state transition
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      state_stage1 <= IDLE;
      request_stage1 <= 4'b0;
      valid_stage1 <= 1'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      request_stage1 <= request;
      valid_stage1 <= 1'b1;
    end
  end

  // Stage 1 combinational logic
  always @(*) begin
    next_state_stage1 = state_stage1;
    case (state_stage1)
      IDLE: next_state_stage1 = (|request) ? GRANT0 : IDLE;
      GRANT0: next_state_stage1 = request[0] ? GRANT0 : GRANT1;
      GRANT1: next_state_stage1 = request[1] ? GRANT1 : GRANT2;
      GRANT2: next_state_stage1 = request[2] ? GRANT2 : IDLE;
    endcase
  end

  // Stage 2: State and request propagation
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      state_stage2 <= IDLE;
      request_stage2 <= 4'b0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= state_stage1;
      request_stage2 <= request_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // Stage 3: Grant generation
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      state_stage3 <= IDLE;
      grant_stage3 <= 4'b0;
      valid_stage3 <= 1'b0;
    end else begin
      state_stage3 <= state_stage2;
      valid_stage3 <= valid_stage2;
      
      if (valid_stage2) begin
        case (state_stage2)
          GRANT0: grant_stage3 <= request_stage2[0] ? 4'b0001 : 4'b0;
          GRANT1: grant_stage3 <= request_stage2[1] ? 4'b0010 : 4'b0;
          GRANT2: grant_stage3 <= request_stage2[2] ? 4'b0100 : 4'b0;
          default: grant_stage3 <= 4'b0;
        endcase
      end else begin
        grant_stage3 <= 4'b0;
      end
    end
  end

  // Output assignment
  assign grant = grant_stage3;

endmodule