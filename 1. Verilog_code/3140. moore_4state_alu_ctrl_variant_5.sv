//SystemVerilog
module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  output reg [1:0] alu_op,
  output reg       done
);
  reg [1:0] state, next_state;
  reg [1:0] opcode_reg;
  reg start_reg;
  reg [1:0] alu_op_next;
  reg done_next;
  
  localparam IDLE   = 2'b00,
             ADD_OP = 2'b01,
             SH_OP  = 2'b10,
             DONE_ST= 2'b11;

  // Stage 1: Input registration
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      opcode_reg <= 2'b00;
      start_reg <= 1'b0;
    end else begin
      opcode_reg <= opcode;
      start_reg <= start;
    end
  end

  // Stage 2: State transition
  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  // Stage 3: Next state and output computation
  always @* begin
    alu_op_next = 2'b00;
    done_next = 1'b0;
    case (state)
      IDLE:   next_state = start_reg ? (opcode_reg == 2'b00 ? ADD_OP : SH_OP) : IDLE;
      ADD_OP: begin alu_op_next = 2'b01; next_state = DONE_ST; end
      SH_OP:  begin alu_op_next = 2'b10; next_state = DONE_ST; end
      DONE_ST:begin done_next = 1'b1;  next_state = IDLE;    end
    endcase
  end

  // Stage 4: Output registration
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      alu_op <= 2'b00;
      done <= 1'b0;
    end else begin
      alu_op <= alu_op_next;
      done <= done_next;
    end
  end
endmodule