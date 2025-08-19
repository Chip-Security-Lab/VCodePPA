//SystemVerilog
module moore_4state_vending(
  input  clk,
  input  rst,
  input  nickel,
  input  dime,
  output reg dispense
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S5 = 2'b01,
             S10= 2'b10,
             S15= 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

  always @(*) begin
    if (state == S0) begin
      if (nickel)
        next_state = S5;
      else if (dime)
        next_state = S10;
      else
        next_state = S0;
    end
    else if (state == S5) begin
      if (nickel)
        next_state = S10;
      else if (dime)
        next_state = S15;
      else
        next_state = S5;
    end
    else if (state == S10) begin
      if (nickel || dime)
        next_state = S15;
      else
        next_state = S10;
    end
    else if (state == S15) begin
      next_state = S0;
    end
    else begin
      next_state = S0;
    end
  end

  always @(*) begin
    dispense = (state == S15);
  end
endmodule