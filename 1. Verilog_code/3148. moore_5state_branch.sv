module moore_5state_branch(
  input  clk,
  input  rst,
  input  sel,
  output reg pathA,
  output reg pathB
);
  reg [2:0] state, next_state;
  localparam S0=3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      S0: next_state = sel ? S1 : S2;
      S1: next_state = S3;
      S2: next_state = S4;
      S3: next_state = S0;
      S4: next_state = S0;
    endcase
  end

  always @* begin
    pathA = 1'b0;
    pathB = 1'b0;
    case (state)
      S1: pathA = 1'b1;
      S2: pathB = 1'b1;
      default: ;
    endcase
  end
endmodule
