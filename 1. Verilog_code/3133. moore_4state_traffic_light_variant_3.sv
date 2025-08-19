//SystemVerilog
module moore_4state_traffic_light_pipeline(
  input  clk,
  input  rst,
  output reg [2:0] light
);
  reg [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  localparam GREEN  = 2'b00,
             YELLOW = 2'b01,
             RED    = 2'b10,
             REDY   = 2'b11;

  // Stage 1: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= GREEN;
    end else begin
      state_stage1 <= state_stage2;
    end
  end

  // Stage 2: Next State Logic
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      next_state_stage1 <= GREEN;
    end else begin
      case (state_stage1)
        GREEN:  next_state_stage1 <= YELLOW;
        YELLOW: next_state_stage1 <= RED;
        RED:    next_state_stage1 <= REDY;
        REDY:   next_state_stage1 <= GREEN;
      endcase
    end
  end

  // Stage 3: State Update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= GREEN;
    end else begin
      state_stage2 <= next_state_stage1;
    end
  end

  // Stage 4: Light Output Logic
  always @* begin
    case (state_stage2)
      GREEN:  light = 3'b100;
      YELLOW: light = 3'b010;
      RED:    light = 3'b001;
      REDY:   light = 3'b011;
    endcase
  end

endmodule