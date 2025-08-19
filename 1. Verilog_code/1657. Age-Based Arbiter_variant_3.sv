//SystemVerilog
module age_based_arbiter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);
  reg [3:0] age [0:CLIENTS-1];
  reg [3:0] max_age;
  reg [CLIENTS-1:0] max_age_idx;
  integer i;
  
  always @(posedge clk) begin
    if (reset) begin
      grants <= 0;
      for (i = 0; i < CLIENTS; i = i + 1) begin
        age[i] <= 0;
      end
    end else begin
      // Increment age for waiting requesters
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && !grants[i]) begin
          age[i] <= age[i] + 1;
        end
      end
      
      // Find oldest requester
      max_age = 0;
      max_age_idx = 0;
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && age[i] > max_age) begin
          max_age = age[i];
          max_age_idx = 1 << i;
        end
      end
      
      // Grant to oldest requester
      grants <= max_age_idx;
    end
  end
endmodule