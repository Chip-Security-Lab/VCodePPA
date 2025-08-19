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

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= IDLE;
      direction <= 1'b0;
    end
    else begin
      state <= next_state;
      direction <= (next_state == UP);
    end
  end

  always @* begin
    case(state)
      IDLE: next_state = up_req ? UP : (down_req ? DOWN : IDLE);
      UP:   next_state = up_req ? UP : IDLE;
      DOWN: next_state = down_req ? DOWN : IDLE;
      default: next_state = IDLE;
    endcase
  end
endmodule