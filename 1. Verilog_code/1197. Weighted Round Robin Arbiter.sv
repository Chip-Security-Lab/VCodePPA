module weighted_rr_arbiter(
  input clk, rst,
  input [2:0] req,
  input [1:0] weights [2:0],  // Weight for each requester
  output reg [2:0] grant
);
  reg [2:0] count [2:0];
  reg [1:0] current;
  
  always @(posedge clk) begin
    if (rst) begin
      current <= 0;
      grant <= 0;
      count[0] <= 0; count[1] <= 0; count[2] <= 0;
    end else begin
      grant <= 0;
      if (req[current] && count[current] < weights[current]) begin
        grant[current] <= 1'b1;
        count[current] <= count[current] + 1;
      end else begin
        count[current] <= 0;
        current <= (current + 1) % 3;
      end
    end
  end
endmodule