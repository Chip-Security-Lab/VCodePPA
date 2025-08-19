module moore_4state_vending(
  input  clk,
  input  rst,
  input  nickel,  // 5分
  input  dime,    // 10分
  output reg dispense
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00, // 0分
             S5 = 2'b01, // 5分
             S10= 2'b10, // 10分
             S15= 2'b11; // 15分

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      S0:  if (nickel) next_state = S5; 
           else if (dime) next_state = S10;
           else next_state = S0;
      S5:  if (nickel) next_state = S10;
           else if (dime) next_state = S15;
           else next_state = S5;
      S10: if (nickel || dime) next_state = S15;
           else next_state = S10;
      S15: next_state = S0;
    endcase
  end

  always @* dispense = (state == S15);
endmodule
