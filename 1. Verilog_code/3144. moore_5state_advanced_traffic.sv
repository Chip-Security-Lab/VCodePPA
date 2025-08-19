module moore_5state_advanced_traffic(
  input  clk,
  input  rst,
  output reg [2:0] light
);
  reg [2:0] state, next_state;
  localparam G   = 3'b000,
             GY  = 3'b001,
             Y   = 3'b010,
             R   = 3'b011,
             RY  = 3'b100;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= G;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      G:   next_state = GY;
      GY:  next_state = Y;
      Y:   next_state = R;
      R:   next_state = RY;
      RY:  next_state = G;
    endcase
  end

  always @* begin
    case (state)
      G:   light = 3'b100;
      GY:  light = 3'b110;
      Y:   light = 3'b010;
      R:   light = 3'b001;
      RY:  light = 3'b011;
    endcase
  end
endmodule
