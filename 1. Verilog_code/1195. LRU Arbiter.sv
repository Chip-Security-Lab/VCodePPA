module lru_arbiter #(parameter CLIENTS=4) (
  input clock, reset,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);
  reg [CLIENTS*2-1:0] lru_count [CLIENTS-1:0];
  integer i, j, highest_idx;
  reg [7:0] highest_count;

  always @(posedge clock) begin
    if (reset) begin
      for (i = 0; i < CLIENTS; i = i + 1) lru_count[i] <= 0;
      grants <= 0;
    end else begin
      grants <= 0;
      highest_count = 0;
      highest_idx = 0;
      
      for (i = 0; i < CLIENTS; i = i + 1) begin
        if (requests[i] && lru_count[i] > highest_count) begin
          highest_count = lru_count[i];
          highest_idx = i;
        end
        lru_count[i] <= lru_count[i] + 1;
      end
      
      if (|requests) begin
        grants[highest_idx] <= 1'b1;
        lru_count[highest_idx] <= 0;
      end
    end
  end
endmodule
