//SystemVerilog
// IEEE 1364-2005 Verilog
module prio_enc_comb_valid #(parameter W=4, A=2)(
  input [W-1:0] requests,
  output reg [A-1:0] encoded_addr,
  output reg valid
);
  integer i;
  
  always @(*) begin
    encoded_addr = 0;
    valid = 0;
    
    // 简化的优先编码器逻辑
    for (i = W-1; i >= 0; i = i-1) begin
      if (requests[i]) begin
        encoded_addr = i[A-1:0];
        valid = 1;
      end
    end
  end
endmodule