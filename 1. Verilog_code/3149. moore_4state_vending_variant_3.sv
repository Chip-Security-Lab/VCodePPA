//SystemVerilog
module moore_4state_vending(
  input  clk,
  input  rst,
  input  nickel,
  input  dime,
  output reg dispense
);

  // Pipeline stage registers
  reg [1:0] state_stage1, state_stage2;
  reg [1:0] next_state_stage1, next_state_stage2;
  reg nickel_stage1, dime_stage1;
  reg nickel_stage2, dime_stage2;
  reg valid_stage1, valid_stage2;
  
  localparam S0 = 2'b00,
             S5 = 2'b01,
             S10= 2'b10,
             S15= 2'b11;

  // Stage 1: Input sampling and state transition
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= S0;
      valid_stage1 <= 1'b0;
    end else begin
      state_stage1 <= next_state_stage1;
      nickel_stage1 <= nickel;
      dime_stage1 <= dime;
      valid_stage1 <= 1'b1;
    end
  end

  // Stage 2: State transition and output generation
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage2 <= S0;
      valid_stage2 <= 1'b0;
    end else begin
      state_stage2 <= next_state_stage2;
      nickel_stage2 <= nickel_stage1;
      dime_stage2 <= dime_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // Stage 1 combinational logic
  always @* begin
    case (state_stage1)
      S0:  next_state_stage1 = nickel_stage1 ? S5 : (dime_stage1 ? S10 : S0);
      S5:  next_state_stage1 = nickel_stage1 ? S10 : (dime_stage1 ? S15 : S5);
      S10: next_state_stage1 = (nickel_stage1 || dime_stage1) ? S15 : S10;
      S15: next_state_stage1 = S0;
    endcase
  end

  // Stage 2 combinational logic
  always @* begin
    next_state_stage2 = state_stage2;
    dispense = (state_stage2 == S15) && valid_stage2;
  end

endmodule