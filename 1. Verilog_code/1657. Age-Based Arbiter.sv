module age_based_arbiter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);
  reg [3:0] age [0:CLIENTS-1];
  integer i;
  always @(posedge clk) begin
    if (reset) begin
      grants <= 0;
      for (i = 0; i < CLIENTS; i = i + 1) age[i] <= 0;
    end else begin
      // Increment age for waiting requesters
      for (i = 0; i < CLIENTS; i = i + 1)
        if (requests[i] && !grants[i]) age[i] <= age[i] + 1;
      
      // Grant to oldest requester
      // Age-based priority logic would go here
    end
  end
endmodule