//SystemVerilog
module moore_3state_up_down_ctrl_pipeline #(parameter DW = 8)(
  input  clk,
  input  rst,
  input  up_req,
  input  down_req,
  output reg direction  // 1=向上, 0=向下
);

  reg [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  localparam IDLE = 2'b00,
             UP   = 2'b01,
             DOWN = 2'b10;

  // State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= IDLE;
      state_stage2 <= IDLE;
    end else begin
      state_stage1 <= next_state_stage1;
      state_stage2 <= state_stage1;
    end
  end

  // Next State Logic
  always @* begin
    case (state_stage1)
      IDLE: if (up_req) next_state_stage1 = UP;
            else if (down_req) next_state_stage1 = DOWN;
            else next_state_stage1 = IDLE;
      UP:   next_state_stage1 = up_req ? UP : IDLE;
      DOWN: next_state_stage1 = down_req ? DOWN : IDLE;
    endcase
  end

  // Direction Output Logic
  always @* begin
    direction = (state_stage2 == UP);
  end

endmodule