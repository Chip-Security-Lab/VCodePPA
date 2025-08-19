module moore_toggle(
  input  clk,
  input  rst,
  input  en,
  output reg out
);
  reg state, next_state;
  localparam S0 = 1'b0,
             S1 = 1'b1;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

  // Next-state logic
  always @* begin
    next_state = state;
    if (en) begin
      case (state)
        S0: next_state = S1;
        S1: next_state = S0;
      endcase
    end
  end

  // Moore输出: 仅依赖当前状态
  always @* out = (state == S1);
endmodule
