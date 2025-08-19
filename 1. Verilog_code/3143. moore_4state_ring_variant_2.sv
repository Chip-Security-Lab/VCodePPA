//SystemVerilog
module moore_4state_ring_pipeline #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output [WIDTH-1:0] ring_out
);

  wire [1:0] state_stage1, state_stage2;
  wire [1:0] next_state_stage1;

  // Instance of state register module
  state_register sr (
    .clk(clk),
    .rst(rst),
    .next_state(next_state_stage1),
    .state_stage1(state_stage1),
    .state_stage2(state_stage2)
  );

  // Instance of next state logic module
  next_state_logic nsl (
    .state_stage1(state_stage1),
    .next_state(next_state_stage1)
  );

  // Instance of output logic module
  output_logic ol (
    .state_stage2(state_stage2),
    .ring_out(ring_out)
  );

endmodule

// State Register Module
module state_register(
  input clk,
  input rst,
  input [1:0] next_state,
  output reg [1:0] state_stage1,
  output reg [1:0] state_stage2
);
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= 2'b00;
      state_stage2 <= 2'b00;
    end else begin
      state_stage1 <= next_state;
      state_stage2 <= state_stage1;
    end
  end
endmodule

// Next State Logic Module
module next_state_logic(
  input [1:0] state_stage1,
  output reg [1:0] next_state
);
  always @* begin
    case (state_stage1)
      2'b00: next_state = 2'b01;
      2'b01: next_state = 2'b10;
      2'b10: next_state = 2'b11;
      2'b11: next_state = 2'b00;
    endcase
  end
endmodule

// Output Logic Module
module output_logic(
  input [1:0] state_stage2,
  output reg [3:0] ring_out
);
  always @* begin
    case (state_stage2)
      2'b00: ring_out = 4'b0001;
      2'b01: ring_out = 4'b0010;
      2'b10: ring_out = 4'b0100;
      2'b11: ring_out = 4'b1000;
    endcase
  end
endmodule