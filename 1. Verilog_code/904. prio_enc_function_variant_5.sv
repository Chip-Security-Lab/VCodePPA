//SystemVerilog
module prio_enc_function #(parameter W=16)(
  input [W-1:0] req,
  output [$clog2(W)-1:0] enc_addr
);

  logic [$clog2(W)-1:0] addr;

  always_comb begin
    addr = '0;
    for (int i = W-1; i >= 0; i--) begin
      if (req[i]) addr = i[$clog2(W)-1:0];
    end
  end

  assign enc_addr = addr;

endmodule