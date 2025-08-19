module moore_2state_parity_gen(
  input  clk,
  input  rst,
  input  in,
  output reg parity
);
  reg state, next_state;
  localparam EVEN = 1'b0,
             ODD  = 1'b1;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= EVEN;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      EVEN: next_state = in ? ODD : EVEN;
      ODD:  next_state = in ? EVEN: ODD;
    endcase
  end

  always @* parity = (state == ODD);
endmodule
