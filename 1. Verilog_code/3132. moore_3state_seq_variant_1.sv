//SystemVerilog
module moore_3state_seq #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] seq_out
);

  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10;

  // Pre-compute output patterns
  wire [WIDTH-1:0] pattern_0 = {WIDTH{1'b0}};
  wire [WIDTH-1:0] pattern_1 = {WIDTH{1'b1}};
  wire [WIDTH-1:0] pattern_2 = {{(WIDTH/2){2'b10}}, {(WIDTH%2){1'b0}}};

  // State transition logic with balanced paths
  always @* begin
    next_state = state; // Default assignment
    case (state)
      S0: next_state = S1;
      S1: next_state = S2;
      S2: next_state = S0;
    endcase
  end

  // Output logic with balanced paths
  always @* begin
    seq_out = pattern_0; // Default assignment
    case (state)
      S0: seq_out = pattern_0;
      S1: seq_out = pattern_1;
      S2: seq_out = pattern_2;
    endcase
  end

  // State register with synchronous reset
  always @(posedge clk) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

endmodule