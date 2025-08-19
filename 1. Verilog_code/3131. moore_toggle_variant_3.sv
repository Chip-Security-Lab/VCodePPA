//SystemVerilog
module moore_toggle(
  input  clk,
  input  rst,
  input  en,
  output reg out
);
  reg state, next_state;
  reg next_state_buf1, next_state_buf2;
  localparam S0 = 1'b0,
             S1 = 1'b1;

  // State register with buffered next_state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= S0;
      next_state_buf1 <= S0;
      next_state_buf2 <= S0;
    end
    else begin
      state <= next_state;
      next_state_buf1 <= next_state;
      next_state_buf2 <= next_state;
    end
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

  // Moore输出: 使用缓冲的状态信号
  always @* out = (state == S1);
endmodule