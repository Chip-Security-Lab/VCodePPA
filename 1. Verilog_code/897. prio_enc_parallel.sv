module prio_enc_parallel #(parameter N=16)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
wire [N-1:0] mask = req - 1;
wire [N-1:0] lead_one = req & ~mask;

integer i;
always @(*) begin
  index = 0;
  for (i=0; i<N; i=i+1)
    if (lead_one[i]) index = i[$clog2(N)-1:0];
end
endmodule