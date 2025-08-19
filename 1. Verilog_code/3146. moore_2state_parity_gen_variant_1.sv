//SystemVerilog
module moore_2state_parity_gen_pipeline(
  input  clk,
  input  rst,
  input  in,
  output reg parity
);
  reg state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  localparam EVEN = 1'b0,
             ODD  = 1'b1;

  // Pipeline stage for state update
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= EVEN;
      state_stage2 <= EVEN;
    end else begin
      state_stage1 <= next_state_stage1;
      state_stage2 <= state_stage1;
    end
  end

  // Pipeline stage for next state logic - converted from case to if-else
  always @* begin
    if (state_stage1 == EVEN) begin
      next_state_stage1 = in ? ODD : EVEN;
    end else if (state_stage1 == ODD) begin
      next_state_stage1 = in ? EVEN : ODD;
    end else begin
      next_state_stage1 = EVEN; // Default case for better synthesis
    end
  end

  // Pipeline stage for parity calculation
  always @* begin
    parity = (state_stage2 == ODD);
  end

endmodule