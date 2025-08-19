//SystemVerilog
module age_based_arbiter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);

  reg [3:0] age [0:CLIENTS-1];
  reg [3:0] max_age;
  reg [CLIENTS-1:0] oldest_req;
  integer i;

  always @(posedge clk) begin
    if (reset) begin
      grants <= 0;
      for (i = 0; i < CLIENTS; i = i + 1) 
        age[i] <= 0;
    end else begin
      // Update ages and find oldest request
      max_age = 0;
      oldest_req = 0;
      
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && !grants[i] && age[i] >= max_age) begin
          max_age = age[i];
          oldest_req = (1 << i);
          age[i] <= age[i] + 1;
        end else if (requests[i] && !grants[i]) begin
          age[i] <= age[i] + 1;
        end else begin
          age[i] <= 0;
        end
      end

      // Grant to oldest requester
      grants <= oldest_req;
    end
  end

endmodule