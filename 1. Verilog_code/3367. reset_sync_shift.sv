module reset_sync_shift #(parameter DEPTH = 3) (
  input  wire clk,
  input  wire rst_n,
  output reg  sync_out
);
  reg [DEPTH-1:0] shift_reg;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      shift_reg <= {DEPTH{1'b0}};
    else
      shift_reg <= {shift_reg[DEPTH-2:0], 1'b1};
  end
  always @* sync_out = shift_reg[DEPTH-1];
endmodule
