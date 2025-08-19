module prio_enc_gray_error #(parameter N=8)(
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] gray_out,
  output error
);
wire [$clog2(N)-1:0] bin_out;
reg [$clog2(N)-1:0] bin_temp;
integer i;

always @(*) begin
  bin_temp = 0;
  for(i=0; i<N; i=i+1)
    if(req[i]) bin_temp = i[$clog2(N)-1:0];
end

assign bin_out = |req ? bin_temp : 0;
always @(*) gray_out = (bin_out >> 1) ^ bin_out;
assign error = ~(|req);
endmodule