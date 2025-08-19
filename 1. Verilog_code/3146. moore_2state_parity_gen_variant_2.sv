//SystemVerilog
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
    if (state == EVEN) begin
      if (in) next_state = ODD;
      else     next_state = EVEN;
    end else if (state == ODD) begin
      if (in) next_state = EVEN;
      else     next_state = ODD;
    end
  end

  always @* parity = (state == ODD);
endmodule