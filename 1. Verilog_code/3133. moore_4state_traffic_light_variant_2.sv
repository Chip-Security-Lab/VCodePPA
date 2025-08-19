//SystemVerilog
module moore_4state_traffic_light(
  input  clk,
  input  rst,
  input  req,          // 将valid信号映射为req信号
  output ack,         // 将ready信号映射为ack信号
  output reg [2:0] light
);
  reg [1:0] state, next_state;
  reg data_valid;
  localparam GREEN  = 2'b00,
             YELLOW = 2'b01,
             RED    = 2'b10,
             REDY   = 2'b11;

  assign ack = data_valid; // 更新ack信号

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= GREEN;
      data_valid <= 1'b0;
    end
    else if (req) begin // 使用req信号
      state <= next_state;
      data_valid <= 1'b1;
    end
    else begin
      data_valid <= 1'b0;
    end
  end

  always @* begin
    case (state)
      GREEN:  next_state = YELLOW;
      YELLOW: next_state = RED;
      RED:    next_state = REDY;
      REDY:   next_state = GREEN;
    endcase
  end

  always @* begin
    case (state)
      GREEN:  light = 3'b100;
      YELLOW: light = 3'b010;
      RED:    light = 3'b001;
      REDY:   light = 3'b011;
    endcase
  end
endmodule