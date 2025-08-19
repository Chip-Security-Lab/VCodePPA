//SystemVerilog
module lru_arbiter #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output reg [N-1:0] grant,
  output reg busy
);

  reg [N*N-1:0] lru_matrix;
  reg [N-1:0] grant_next;
  reg busy_next;
  reg found;
  integer k;
  
  // Intermediate signals for priority encoding
  wire [N-1:0] priority_mask;
  wire [N-1:0] valid_request;
  wire [N-1:0] grant_candidate;
  
  // Priority encoding logic
  assign valid_request = request & ~grant_next;
  assign priority_mask = valid_request & ~({valid_request[N-2:0], 1'b0} | {N{1'b0}});
  assign grant_candidate = priority_mask & {N{!found}};
  
  always @(*) begin
    found = 1'b0;
    grant_next = {N{1'b0}};
    busy_next = |request;
    
    for (k = 0; k < N; k = k + 1) begin
      if (grant_candidate[k]) begin
        grant_next = (1 << k);
        found = 1'b1;
      end
    end
  end
  
  always @(posedge clk) begin
    if (rst) begin
      lru_matrix <= {N*N{1'b0}};
      grant <= {N{1'b0}};
      busy <= 1'b0;
    end else begin
      grant <= grant_next;
      busy <= busy_next;
    end
  end
endmodule