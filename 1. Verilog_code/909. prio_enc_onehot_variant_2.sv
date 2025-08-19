//SystemVerilog
module prio_enc_onehot #(parameter W=5)(
  input [W-1:0] req_onehot,
  output reg [W-1:0] enc_out
);

  always @(*) begin
    enc_out = 0;
    case (1'b1)
      req_onehot[0]: enc_out = {{W-1{1'b0}}, 1'b1};
      req_onehot[1]: enc_out = {{W-2{1'b0}}, 1'b1, 1'b0};
      req_onehot[2]: enc_out = {{W-3{1'b0}}, 1'b1, 2'b0};
      req_onehot[3]: enc_out = {{W-4{1'b0}}, 1'b1, 3'b0};
      req_onehot[4]: enc_out = {{W-5{1'b0}}, 1'b1, 4'b0};
      default: enc_out = 0;
    endcase
  end

endmodule