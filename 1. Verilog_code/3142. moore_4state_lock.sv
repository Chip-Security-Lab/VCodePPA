module moore_4state_lock(
  input  clk,
  input  rst,
  input  in,
  output reg locked
);
  reg [1:0] state, next_state;
  localparam WAIT = 2'b00,
             GOT1 = 2'b01,
             GOT10= 2'b10,
             UNLK = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= WAIT;
    else     state <= next_state;
  end

  always @(*) begin
    locked = 1'b1; // 默认锁定
    next_state = state; // 默认保持当前状态
    
    case (state)
      WAIT:  if (in) next_state = GOT1;
      GOT1:  if (!in) next_state = GOT10;
             else next_state = GOT1;
      GOT10: if (in) next_state = UNLK;
             else next_state = WAIT;
      UNLK:  begin
        locked = 1'b0; // 一旦解锁就保持解锁
        next_state = UNLK;
      end
      default: next_state = WAIT;
    endcase
  end
endmodule