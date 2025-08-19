//SystemVerilog
module valid_ready_handshake(
  input  clk,
  input  rst,
  input  start,
  output reg valid,
  input  ready,
  output reg done
);
  reg [1:0] state, next_state;
  localparam IDLE     = 2'b00,
             WAIT_READY = 2'b01,
             COMPLETE = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= IDLE;
    else     state <= next_state;
  end

  always @* begin
    if (state == IDLE) begin
      valid = start;
      next_state = start ? WAIT_READY : IDLE;
    end
    else if (state == WAIT_READY) begin
      valid = 1'b1;
      next_state = ready ? COMPLETE : WAIT_READY;
    end
    else if (state == COMPLETE) begin
      valid = 1'b0;
      next_state = IDLE;
    end
    else begin
      valid = 1'b0;
      next_state = IDLE;
    end
  end

  always @* done = (state == COMPLETE);
endmodule