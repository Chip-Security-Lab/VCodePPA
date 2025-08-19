//SystemVerilog
module moore_2state_parity_gen(
  input  clk,
  input  rst,
  input  in,
  output reg parity
);

  wire state, next_state;
  wire next_state_signal;

  // State Machine Module
  state_machine sm (
    .clk(clk),
    .rst(rst),
    .in(in),
    .next_state(next_state_signal),
    .state(state)
  );

  // Parity Generation Module
  parity_gen pg (
    .state(state),
    .parity(parity)
  );

  // Assign the next state to the output wire
  assign next_state = next_state_signal;

endmodule

// State Machine Submodule
module state_machine(
  input  clk,
  input  rst,
  input  in,
  output reg next_state,
  output reg state
);
  localparam EVEN = 1'b0,
             ODD  = 1'b1;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= EVEN;
    else     state <= next_state;
  end

  always @* begin
    if (state == EVEN) begin
      if (in) next_state = ODD;
      else    next_state = EVEN;
    end
    else begin
      if (in) next_state = EVEN;
      else    next_state = ODD;
    end
  end
endmodule

// Parity Generation Submodule
module parity_gen(
  input state,
  output reg parity
);
  always @* begin
    if (state == 1'b1) parity = 1'b1; // ODD
    else               parity = 1'b0; // EVEN
  end
endmodule