module moore_3state_glitch_filter(
  input  clk,
  input  rst,
  input  in,
  output reg out
);
  reg [1:0] state, next_state;
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= STABLE0;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      STABLE0: next_state = in ? TRANS : STABLE0;
      TRANS:   next_state = in ? STABLE1 : STABLE0;
      STABLE1: next_state = in ? STABLE1 : TRANS;
    endcase
  end

  always @* out = (state == STABLE1);
endmodule
