//SystemVerilog
module moore_toggle(
  input  clk,
  input  rst,
  input  en,
  output reg out
);
  reg state;
  reg next_state_reg;
  wire next_state;
  
  assign next_state = en ? ~state : state;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= 1'b0;
      next_state_reg <= 1'b0;
    end
    else begin
      state <= next_state;
      next_state_reg <= next_state;
    end
  end

  always @(*) begin
    out = next_state_reg;
  end
endmodule