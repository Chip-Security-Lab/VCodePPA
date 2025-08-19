module daisy_chain_arbiter(
  input clk, reset,
  input [3:0] request,
  output reg [3:0] grant
);
  wire [4:0] chain;
  assign chain[0] = 1'b1;  // First stage always has priority
  
  generate
    genvar i;
    for (i = 0; i < 4; i = i + 1) begin: daisy
      assign chain[i+1] = chain[i] & ~request[i];
    end
  endgenerate
  
  always @(posedge clk) begin
    if (reset) grant <= 4'h0;
    else begin
      grant[0] <= request[0] & chain[0];
      grant[1] <= request[1] & chain[1];
      grant[2] <= request[2] & chain[2];
      grant[3] <= request[3] & chain[3];
    end
  end
endmodule