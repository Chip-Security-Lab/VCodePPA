//SystemVerilog
module mask_arbiter(
  input i_clk, i_rstn,
  input [7:0] i_req,
  input [7:0] i_mask,
  output reg [7:0] o_grant
);

  // 组合逻辑模块
  wire [7:0] masked_req;
  wire [7:0] next_grant;
  
  // 掩码组合逻辑
  assign masked_req = i_req & i_mask;
  
  // 优先级编码器组合逻辑
  assign next_grant = (masked_req[7]) ? 8'b10000000 :
                     (masked_req[6]) ? 8'b01000000 :
                     (masked_req[5]) ? 8'b00100000 :
                     (masked_req[4]) ? 8'b00010000 :
                     (masked_req[3]) ? 8'b00001000 :
                     (masked_req[2]) ? 8'b00000100 :
                     (masked_req[1]) ? 8'b00000010 :
                     (masked_req[0]) ? 8'b00000001 : 8'h0;
  
  // 时序逻辑模块
  always @(posedge i_clk or negedge i_rstn) begin
    if (!i_rstn) 
      o_grant <= 8'h0;
    else 
      o_grant <= next_grant;
  end

endmodule