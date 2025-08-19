module moore_4state_traffic_light(
  input  clk,
  input  rst,
  output reg [2:0] light
);
  reg [1:0] state, next_state;
  localparam GREEN  = 2'b00,
             YELLOW = 2'b01,
             RED    = 2'b10,
             REDY   = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= GREEN;
    else     state <= next_state;
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
