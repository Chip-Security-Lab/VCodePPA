module mask_arbiter(
  input i_clk, i_rstn,
  input [7:0] i_req,
  input [7:0] i_mask,
  output reg [7:0] o_grant
);
  reg [7:0] masked_req;
  always @(*) begin
    masked_req = i_req & i_mask;
  end
  
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) o_grant <= 8'h0;
    else begin
      o_grant <= 8'h0;
      casez (masked_req)
        8'b1???????: o_grant <= 8'b10000000;
        8'b01??????: o_grant <= 8'b01000000;
        // Continue for all bits
        default: o_grant <= 8'h0;
      endcase
    end
  end
endmodule