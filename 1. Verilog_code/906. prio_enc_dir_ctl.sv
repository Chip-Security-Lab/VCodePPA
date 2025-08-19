module prio_enc_dir_ctl #(parameter N=8)(
  input clk, dir, // 0:LSB-first 1:MSB-first
  input [N-1:0] req,
  output reg [$clog2(N)-1:0] index
);
integer i;
always @(posedge clk) begin
  index <= 0;
  if(dir) begin // MSB first
    for(i=N-1; i>=0; i=i-1)
      if(req[i]) index <= i[$clog2(N)-1:0];
  end
  else begin    // LSB first
    for(i=0; i<N; i=i+1)
      if(req[i]) index <= i[$clog2(N)-1:0];
  end
end
endmodule