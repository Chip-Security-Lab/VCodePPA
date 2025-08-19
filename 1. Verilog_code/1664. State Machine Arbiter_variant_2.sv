//SystemVerilog
module fsm_arbiter(
  input wire clock, resetn,
  input wire [3:0] request,
  output reg [3:0] grant
);
  localparam IDLE = 2'b00, GRANT0 = 2'b01, 
             GRANT1 = 2'b10, GRANT2 = 2'b11;
  
  // Pipeline stage 1 registers
  reg [1:0] state_stage1, next_state_stage1;
  reg [3:0] request_stage1;
  reg request_valid_stage1;
  
  // Pipeline stage 2 registers
  reg [1:0] state_stage2;
  reg [3:0] grant_next_stage2;
  reg [3:0] request_stage2;
  
  // Pipeline stage 3 registers
  reg [3:0] grant_stage3;
  
  // Stage 1: Request validation and state update
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      state_stage1 <= IDLE;
      request_stage1 <= 4'b0;
      request_valid_stage1 <= 1'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      request_stage1 <= request;
      request_valid_stage1 <= |request;
    end
  end
  
  // Stage 1 combinational logic
  always @(*) begin
    next_state_stage1 = state_stage1;
    case (state_stage1)
      IDLE: if (request_valid_stage1) next_state_stage1 = GRANT0;
      GRANT0: if (!request_stage1[0]) next_state_stage1 = GRANT1;
      GRANT1: if (!request_stage1[1]) next_state_stage1 = GRANT2;
      GRANT2: if (!request_stage1[2]) next_state_stage1 = IDLE;
      default: next_state_stage1 = IDLE;
    endcase
  end
  
  // Stage 2: Grant calculation
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      state_stage2 <= IDLE;
      grant_next_stage2 <= 4'b0;
      request_stage2 <= 4'b0;
    end else begin
      state_stage2 <= state_stage1;
      request_stage2 <= request_stage1;
      case (state_stage1)
        GRANT0: grant_next_stage2 <= {4{request_stage1[0]}} & 4'b0001;
        GRANT1: grant_next_stage2 <= {4{request_stage1[1]}} & 4'b0010;
        GRANT2: grant_next_stage2 <= {4{request_stage1[2]}} & 4'b0100;
        default: grant_next_stage2 <= 4'b0;
      endcase
    end
  end
  
  // Stage 3: Grant output
  always @(posedge clock or negedge resetn) begin
    if (!resetn) begin
      grant_stage3 <= 4'b0;
    end else begin
      grant_stage3 <= grant_next_stage2;
    end
  end
  
  assign grant = grant_stage3;
endmodule