//SystemVerilog
module prio_enc_onehot #(parameter W=5)(
  input [W-1:0] req_onehot,
  output [W-1:0] enc_out
);

  // 实例化编码器子模块
  enc_core #(.W(W)) u_enc_core(
    .req_onehot(req_onehot),
    .enc_out(enc_out)
  );

endmodule

// 编码器核心逻辑子模块
module enc_core #(parameter W=5)(
  input [W-1:0] req_onehot,
  output reg [W-1:0] enc_out
);

  integer i;
  always @(*) begin
    enc_out = 0;
    for(i=0; i<W; i=i+1)
      if(req_onehot[i]) enc_out = 1 << i;
  end

endmodule