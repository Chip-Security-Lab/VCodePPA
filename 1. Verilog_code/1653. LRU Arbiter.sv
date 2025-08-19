module lru_arbiter #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output reg [N-1:0] grant,
  output reg busy
);
  reg [N*N-1:0] lru_matrix;
  integer k;
  reg found;
  always @(posedge clk) begin
    if (rst) begin
      lru_matrix <= 0; grant <= 0; busy <= 0;
    end else if (|request) begin
      busy <= 1;
      found = 0;
      grant <= 0;
      for (k = 0; k < N; k = k + 1) begin
        if (!found && request[k] && !grant[k]) begin
          grant <= (1 << k); // Update LRU matrix here
          found = 1;
        end
      end
    end else begin
      busy <= 0; grant <= 0;
    end
  end
endmodule