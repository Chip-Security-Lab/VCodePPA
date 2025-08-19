module reset_chain_monitor (
  input wire clk,
  input wire [3:0] reset_chain,
  output reg reset_chain_error
);
  always @(posedge clk) begin
    if (reset_chain != 4'b0000 && reset_chain != 4'b1111)
      reset_chain_error <= 1;
  end
endmodule
