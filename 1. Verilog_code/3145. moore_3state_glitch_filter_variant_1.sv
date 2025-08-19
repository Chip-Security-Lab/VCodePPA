//SystemVerilog
// State transition logic module
module state_transition_logic(
  input  clk,
  input  rst,
  input  in,
  output reg [1:0] state
);
  reg [1:0] next_state;
  localparam STABLE0 = 2'b00,
             TRANS   = 2'b01,
             STABLE1 = 2'b10;

  // Signed multiplication optimization
  wire signed [1:0] state_signed = state;
  wire signed [1:0] next_state_signed;
  wire signed [1:0] state_transition = (state_signed * 2'sb01) + (in ? 2'sb01 : 2'sb00);

  always @(posedge clk or posedge rst) begin
    if (rst) 
      state <= STABLE0;
    else     
      state <= next_state;
  end

  always @* begin
    case (state)
      STABLE0: begin
        next_state = state_transition[1:0];
      end
      TRANS: begin
        next_state = state_transition[1:0];
      end
      STABLE1: begin
        next_state = state_transition[1:0];
      end
      default: begin
        next_state = STABLE0;
      end
    endcase
  end
endmodule

// Output generation module
module output_generation(
  input  [1:0] state,
  output reg out
);
  localparam STABLE1 = 2'b10;

  always @* begin
    if (state == STABLE1)
      out = 1'b1;
    else
      out = 1'b0;
  end
endmodule

// Top-level module
module moore_3state_glitch_filter(
  input  clk,
  input  rst,
  input  in,
  output out
);
  wire [1:0] state;

  state_transition_logic state_logic(
    .clk(clk),
    .rst(rst),
    .in(in),
    .state(state)
  );

  output_generation output_gen(
    .state(state),
    .out(out)
  );
endmodule