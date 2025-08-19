//SystemVerilog
module moore_4state_lock(
  input  clk,
  input  rst,
  input  in,
  output reg locked
);
  // 状态定义
  reg [1:0] state, next_state;
  localparam WAIT = 2'b00,
             GOT1 = 2'b01,
             GOT10= 2'b10,
             UNLK = 2'b11;

  // 时序状态更新逻辑
  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= WAIT;
    else     
      state <= next_state;
  end

  // 状态转换逻辑
  always @(*) begin
    // 默认保持当前状态
    next_state = state;

    // 优化比较逻辑
    case (state)
      WAIT:  
        next_state = (in) ? GOT1 : WAIT;
      
      GOT1:  
        next_state = (!in) ? GOT10 : GOT1;
      
      GOT10: 
        next_state = (in) ? UNLK : WAIT;
      
      UNLK:  
        next_state = UNLK; // 已解锁状态保持
      
      default: 
        next_state = WAIT;
    endcase
  end

  // 输出逻辑
  always @(*) begin
    // 默认锁定状态
    locked = (state == UNLK) ? 1'b0 : 1'b1; // 解锁或锁定
  end
endmodule