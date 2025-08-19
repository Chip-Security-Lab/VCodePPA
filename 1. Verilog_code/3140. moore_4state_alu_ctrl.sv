module moore_4state_alu_ctrl(
  input  clk,
  input  rst,
  input  start,
  input  [1:0] opcode,
  output reg [1:0] alu_op,
  output reg       done
);
  reg [1:0] state, next_state;
  localparam IDLE   = 2'b00,
             ADD_OP = 2'b01,
             SH_OP  = 2'b10,
             DONE_ST= 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    alu_op = 2'b00;
    done   = 1'b0;
    case (state)
      IDLE:   next_state = start ? (opcode == 2'b00 ? ADD_OP : SH_OP) : IDLE;
      ADD_OP: begin alu_op = 2'b01; next_state = DONE_ST; end
      SH_OP:  begin alu_op = 2'b10; next_state = DONE_ST; end
      DONE_ST:begin done   = 1'b1;  next_state = IDLE;    end
    endcase
  end
endmodule
