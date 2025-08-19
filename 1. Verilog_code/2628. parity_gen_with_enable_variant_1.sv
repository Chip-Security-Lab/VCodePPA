//SystemVerilog
module parity_gen_with_enable_pipeline(
  input clk, enable,
  input [15:0] data_word,
  output reg parity_result
);

  // Pipeline registers
  reg [7:0] xor_stage1_reg;
  reg [3:0] xor_stage2_reg;
  reg [1:0] xor_stage3_reg;
  reg parity_temp_reg;

  // First stage XOR - optimized to reduce logic depth
  always @(posedge clk) begin
    if (enable) begin
      xor_stage1_reg[0] <= data_word[0] ^ data_word[1];
      xor_stage1_reg[1] <= data_word[2] ^ data_word[3];
      xor_stage1_reg[2] <= data_word[4] ^ data_word[5];
      xor_stage1_reg[3] <= data_word[6] ^ data_word[7];
      xor_stage1_reg[4] <= data_word[8] ^ data_word[9];
      xor_stage1_reg[5] <= data_word[10] ^ data_word[11];
      xor_stage1_reg[6] <= data_word[12] ^ data_word[13];
      xor_stage1_reg[7] <= data_word[14] ^ data_word[15];
    end
  end

  // Second stage XOR - optimized to reduce logic depth
  always @(posedge clk) begin
    if (enable) begin
      xor_stage2_reg[0] <= xor_stage1_reg[0] ^ xor_stage1_reg[1];
      xor_stage2_reg[1] <= xor_stage1_reg[2] ^ xor_stage1_reg[3];
      xor_stage2_reg[2] <= xor_stage1_reg[4] ^ xor_stage1_reg[5];
      xor_stage2_reg[3] <= xor_stage1_reg[6] ^ xor_stage1_reg[7];
    end
  end

  // Third stage XOR - optimized to reduce logic depth
  always @(posedge clk) begin
    if (enable) begin
      xor_stage3_reg[0] <= xor_stage2_reg[0] ^ xor_stage2_reg[1];
      xor_stage3_reg[1] <= xor_stage2_reg[2] ^ xor_stage2_reg[3];
    end
  end

  // Final XOR and output
  always @(posedge clk) begin
    if (enable) begin
      parity_temp_reg <= xor_stage3_reg[0] ^ xor_stage3_reg[1];
      parity_result <= parity_temp_reg;
    end
  end

endmodule