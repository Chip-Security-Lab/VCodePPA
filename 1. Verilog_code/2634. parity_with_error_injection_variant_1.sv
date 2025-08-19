//SystemVerilog
module parity_with_error_injection(
  input [15:0] data_in,
  input error_inject,
  output reg parity
);

  // Wallace tree implementation for parity calculation
  wire [7:0] stage1_parity;
  wire [3:0] stage2_parity;
  wire [1:0] stage3_parity;
  wire final_parity;

  // Stage 1: 8-bit XOR reduction
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : stage1
      assign stage1_parity[i] = data_in[2*i] ^ data_in[2*i+1];
    end
  endgenerate

  // Stage 2: 4-bit XOR reduction
  generate
    for (i = 0; i < 4; i = i + 1) begin : stage2
      assign stage2_parity[i] = stage1_parity[2*i] ^ stage1_parity[2*i+1];
    end
  endgenerate

  // Stage 3: 2-bit XOR reduction
  generate
    for (i = 0; i < 2; i = i + 1) begin : stage3
      assign stage3_parity[i] = stage2_parity[2*i] ^ stage2_parity[2*i+1];
    end
  endgenerate

  // Final stage
  assign final_parity = stage3_parity[0] ^ stage3_parity[1];

  // Error injection
  always @(*) begin
    parity = final_parity ^ error_inject;
  end

endmodule