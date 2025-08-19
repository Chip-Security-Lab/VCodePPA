//SystemVerilog
module mask_arbiter(
  input i_clk, i_rstn,
  input [7:0] i_req,
  input [7:0] i_mask,
  output reg [7:0] o_grant
);
  
  wire [7:0] masked_req = i_req & i_mask;
  wire [7:0] grant_comb;
  
  // 提前计算优先级编码
  assign grant_comb[7] = masked_req[7];
  assign grant_comb[6] = ~masked_req[7] & masked_req[6];
  assign grant_comb[5] = ~masked_req[7] & ~masked_req[6] & masked_req[5];
  assign grant_comb[4] = ~masked_req[7] & ~masked_req[6] & ~masked_req[5] & masked_req[4];
  assign grant_comb[3] = ~masked_req[7] & ~masked_req[6] & ~masked_req[5] & ~masked_req[4] & masked_req[3];
  assign grant_comb[2] = ~masked_req[7] & ~masked_req[6] & ~masked_req[5] & ~masked_req[4] & ~masked_req[3] & masked_req[2];
  assign grant_comb[1] = ~masked_req[7] & ~masked_req[6] & ~masked_req[5] & ~masked_req[4] & ~masked_req[3] & ~masked_req[2] & masked_req[1];
  assign grant_comb[0] = ~masked_req[7] & ~masked_req[6] & ~masked_req[5] & ~masked_req[4] & ~masked_req[3] & ~masked_req[2] & ~masked_req[1] & masked_req[0];
  
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) begin
      o_grant <= 8'h0;
    end
    else begin
      o_grant <= grant_comb;
    end
  end
endmodule