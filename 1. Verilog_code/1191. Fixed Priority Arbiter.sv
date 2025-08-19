module fixed_priority_arbiter #(parameter N=4) (
  input wire clk, rst_n,
  input wire [N-1:0] req,
  output reg [N-1:0] grant
);
  integer i;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) grant <= 0;
    else begin
      grant <= 0;
      for (i = 0; i < N; i = i + 1) begin
        if (req[i] && !grant) grant[i] <= 1'b1;
      end
    end
  end
endmodule