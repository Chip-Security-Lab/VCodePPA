//SystemVerilog
module moore_4state_lock(
  input  clk,
  input  rst,
  input  in,
  output reg locked
);
  // State registers
  reg [3:0] state, next_state; // Changed to 4-bit for one-hot encoding
  
  // State parameters using one-hot encoding
  localparam WAIT  = 4'b0001,
             GOT1  = 4'b0010,
             GOT10 = 4'b0100,
             UNLK  = 4'b1000;
  
  // Add buffering registers
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= WAIT; // Reset to WAIT state
    end
    else begin
      state <= next_state; // Update state to next state
    end
  end

  // Next state combinational logic
  always @(*) begin
    locked = 1'b1; // 默认锁定
    next_state = 4'b0000; // 默认保持当前状态为无状态
    
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
      default: next_state = WAIT; // Default state
    endcase
  end
endmodule