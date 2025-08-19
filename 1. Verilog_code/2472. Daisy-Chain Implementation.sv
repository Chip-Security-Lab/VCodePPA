module daisy_chain_intr_ctrl(
  input clk, rst_n,
  input [3:0] requests,
  input chain_in,
  output reg [1:0] local_id,
  output chain_out,
  output reg grant
);
  reg local_req;
  
  always @(*) begin
    local_req = |requests;
    casez (requests)
      4'b???1: local_id = 2'd0;
      4'b??10: local_id = 2'd1;
      4'b?100: local_id = 2'd2;
      4'b1000: local_id = 2'd3;
      default: local_id = 2'd0;
    endcase
  end
  
  assign chain_out = chain_in & ~local_req;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      grant <= 1'b0;
    else
      grant <= local_req & chain_in;
  end
endmodule