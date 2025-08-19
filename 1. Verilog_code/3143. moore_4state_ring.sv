module moore_4state_ring #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] ring_out
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state;
  end

  always @* begin
    case (state)
      S0: next_state = S1;
      S1: next_state = S2;
      S2: next_state = S3;
      S3: next_state = S0;
    endcase
  end

  always @* begin
    case (state)
      S0: ring_out = 4'b0001;
      S1: ring_out = 4'b0010;
      S2: ring_out = 4'b0100;
      S3: ring_out = 4'b1000;
    endcase
  end
endmodule
