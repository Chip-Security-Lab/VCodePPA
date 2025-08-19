//SystemVerilog
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
    if (state == S0) begin
      next_state = sel ? S1 : S2;
    end
    else if (state == S1) begin
      next_state = S3;
    end
    else if (state == S2) begin
      next_state = S4;
    end
    else if (state == S3) begin
      next_state = S0;
    end
    else if (state == S4) begin
      next_state = S0;
    end
    else begin
      next_state = S0;
    end
  end

  always @* begin
    pathA = 1'b0;
    pathB = 1'b0;
    if (state == S1) begin
      pathA = 1'b1;
    end
    else if (state == S2) begin
      pathB = 1'b1;
    end
  end
endmodule