module prio_enc_pipe_stage #(parameter W=32, A=5)(
  input clk, rst,
  input [W-1:0] req,
  output reg [A-1:0] addr_reg
);
reg [W-1:0] req_pipe;
integer i;
always @(posedge clk) begin
  if (rst) begin
    req_pipe <= 0;
    addr_reg <= 0;
  end
  else begin
    req_pipe <= req;
    addr_reg <= 0;
    for(i=0; i<W; i=i+1)
      if(req_pipe[i]) addr_reg <= i[A-1:0];
  end
end
endmodule