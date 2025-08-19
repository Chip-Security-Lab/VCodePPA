module moore_3state_handshake(
  input  clk,
  input  rst,
  input  start,
  input  ack,
  output reg done
);
  reg [1:0] state, next_state;
  localparam IDLE     = 2'b00,
             WAIT_ACK = 2'b01,
             COMPLETE = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      IDLE:      next_state = start ? WAIT_ACK : IDLE;
      WAIT_ACK:  next_state = ack   ? COMPLETE : WAIT_ACK;
      COMPLETE:  next_state = IDLE;
    endcase
  end

  always @* done = (state == COMPLETE);
endmodule
