//SystemVerilog
module moore_3state_up_down_ctrl #(parameter DW = 8)(
  input  clk,
  input  rst,
  input  up_req,
  input  down_req,
  output reg direction  // 1=向上, 0=向下
);
  reg [1:0] state, next_state;
  localparam IDLE = 2'b00,
             UP   = 2'b01,
             DOWN = 2'b10;

  // 时序逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
    end
    else begin
      state <= next_state;
    end
  end

  // 组合逻辑
  always @(*) begin
    // 状态转移逻辑
    case (state)
      IDLE: if (up_req) next_state = UP;
            else if (down_req) next_state = DOWN;
            else next_state = IDLE;
      UP:   next_state = up_req ? UP : IDLE;
      DOWN: next_state = down_req ? DOWN : IDLE;
      default: next_state = IDLE;
    endcase
    
    // 输出逻辑
    direction = (state == UP);
  end
endmodule