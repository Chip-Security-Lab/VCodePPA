//SystemVerilog
module moore_4state_traffic_light(
  input  clk,
  input  rst,
  input  req,          // 请求信号
  output reg ack,      // 应答信号
  output reg [2:0] light
);
  reg [1:0] state, next_state;
  localparam GREEN  = 2'b00,
             YELLOW = 2'b01,
             RED    = 2'b10,
             REDY   = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= GREEN;
      ack <= 0; // 复位时应答信号为0
    end else if (req) begin
      state <= next_state; // 当请求信号有效时，更新状态
      ack <= 1; // 发送应答信号
    end else begin
      ack <= 0; // 请求信号无效时，清除应答信号
    end
  end

  always @* begin
    if (state == GREEN) begin
      next_state = YELLOW;
    end else if (state == YELLOW) begin
      next_state = RED;
    end else if (state == RED) begin
      next_state = REDY;
    end else if (state == REDY) begin
      next_state = GREEN;
    end else begin
      next_state = GREEN; // 默认状态处理
    end
  end

  always @* begin
    if (state == GREEN) begin
      light = 3'b100;
    end else if (state == YELLOW) begin
      light = 3'b010;
    end else if (state == RED) begin
      light = 3'b001;
    end else if (state == REDY) begin
      light = 3'b011;
    end else begin
      light = 3'b100; // 默认灯光状态为绿灯
    end
  end
endmodule