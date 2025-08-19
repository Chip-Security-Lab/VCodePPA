module masked_priority_arbiter(
  input wire clk, rst_n,
  input wire [3:0] req,
  input wire [3:0] mask,
  output reg [3:0] grant
);
  wire [3:0] masked_req = req & ~mask;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) grant <= 4'h0;
    else begin
      grant <= 4'h0;
      if (masked_req[0]) grant[0] <= 1'b1;
      else if (masked_req[1]) grant[1] <= 1'b1;
      else if (masked_req[2]) grant[2] <= 1'b1;
      else if (masked_req[3]) grant[3] <= 1'b1;
      else if (req[0] && !mask[0]) grant[0] <= 1'b1;
      else if (req[1] && !mask[1]) grant[1] <= 1'b1;
      else if (req[2] && !mask[2]) grant[2] <= 1'b1;
      else if (req[3] && !mask[3]) grant[3] <= 1'b1;
    end
  end
endmodule
