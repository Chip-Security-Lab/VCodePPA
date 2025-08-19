//SystemVerilog
module req_ack_toggle(
  input  clk,
  input  rst,
  input  req,  // 请求信号
  output reg ack, // 应答信号
  output reg out
);
  reg state, next_state;
  localparam S0 = 1'b0,
             S1 = 1'b1;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= S0;
      ack <= 1'b0; // 初始化应答信号
    end else begin
      state <= next_state;
      ack <= (next_state == S1); // 当状态为S1时应答
    end
  end

  // Next-state logic
  always @* begin
    next_state = state;
    if (req) begin // 当请求信号有效时
      case (state)
        S0: next_state = S1;
        S1: next_state = S0;
      endcase
    end
  end

  // Moore输出: 仅依赖当前状态
  always @* out = (state == S1);
endmodule