//SystemVerilog
module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  output [1:0] alu_op,
  output       done
);

  wire [1:0] state_stage1;
  wire [1:0] state_stage2;
  wire [1:0] next_state_stage1;
  wire [1:0] next_state_stage2;
  wire [1:0] alu_op_stage1;
  wire [1:0] alu_op_stage2;
  wire done_stage1;
  wire done_stage2;
  
  // Stage 1 State Register
  state_register u_state_reg_stage1 (
    .clk(clk),
    .rst(rst),
    .next_state(next_state_stage1),
    .state(state_stage1)
  );

  // Stage 2 State Register
  state_register u_state_reg_stage2 (
    .clk(clk),
    .rst(rst),
    .next_state(next_state_stage2),
    .state(state_stage2)
  );

  // Stage 1 Next State Logic
  next_state_logic u_next_state_logic_stage1 (
    .state(state_stage1),
    .start(start),
    .opcode(opcode),
    .next_state(next_state_stage1)
  );

  // Stage 2 Next State Logic
  next_state_logic u_next_state_logic_stage2 (
    .state(state_stage2),
    .start(1'b0),
    .opcode(2'b00),
    .next_state(next_state_stage2)
  );

  // Stage 1 ALU Operation Logic
  alu_operation u_alu_operation_stage1 (
    .state(state_stage1),
    .alu_op(alu_op_stage1),
    .done(done_stage1)
  );

  // Stage 2 ALU Operation Logic
  alu_operation u_alu_operation_stage2 (
    .state(state_stage2),
    .alu_op(alu_op_stage2),
    .done(done_stage2)
  );

  // Output Pipeline Register
  reg [1:0] alu_op_reg;
  reg done_reg;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      alu_op_reg <= 2'b00;
      done_reg <= 1'b0;
    end else begin
      alu_op_reg <= alu_op_stage2;
      done_reg <= done_stage2;
    end
  end

  assign alu_op = alu_op_reg;
  assign done = done_reg;

endmodule

module state_register(
  input clk,
  input rst,
  input [1:0] next_state,
  output reg [1:0] state
);
  always @(posedge clk or posedge rst) begin
    if (rst) state <= 2'b00;
    else     state <= next_state;
  end
endmodule

module next_state_logic(
  input [1:0] state,
  input start,
  input [1:0] opcode,
  output reg [1:0] next_state
);
  localparam IDLE   = 2'b00,
             ADD_OP = 2'b01,
             SH_OP  = 2'b10,
             DONE_ST= 2'b11;

  always @* begin
    case (state)
      IDLE:   next_state = start ? (opcode == 2'b00 ? ADD_OP : SH_OP) : IDLE;
      ADD_OP: next_state = DONE_ST;
      SH_OP:  next_state = DONE_ST;
      DONE_ST: next_state = IDLE;
      default: next_state = IDLE;
    endcase
  end
endmodule

module alu_operation(
  input [1:0] state,
  output reg [1:0] alu_op,
  output reg done
);
  always @* begin
    alu_op = 2'b00;
    done   = 1'b0;
    case (state)
      2'b01: begin alu_op = 2'b01; done = 1'b0; end
      2'b10: begin alu_op = 2'b10; done = 1'b0; end
      2'b11: begin done = 1'b1; end
      default: begin alu_op = 2'b00; done = 1'b0; end
    endcase
  end
endmodule