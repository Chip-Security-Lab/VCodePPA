//SystemVerilog
module parity_gen_with_enable(
  input clk, enable,
  input [15:0] data_word,
  output reg parity_result
);

  // Stage 1: First level XOR (split into two stages)
  reg [7:0] stage1_result;
  reg stage1_enable;
  
  // Stage 2: Split first level XOR (first half)
  reg [3:0] stage2_result1;
  reg stage2_enable1;

  // Stage 3: Split first level XOR (second half)
  reg [3:0] stage2_result2;
  reg stage2_enable2;

  // Stage 4: Second level XOR
  reg [1:0] stage3_result;
  reg stage3_enable;
  
  // Stage 5: Final XOR
  reg stage4_enable;

  always @(posedge clk) begin
    // Stage 1: Process first 8 bits
    stage1_enable <= enable;
    if (enable) begin
      stage1_result <= data_word[15:8] ^ data_word[7:0];
    end

    // Stage 2: Process first half of stage 1 result
    stage2_enable1 <= stage1_enable;
    if (stage1_enable) begin
      stage2_result1 <= stage1_result[7:4] ^ stage1_result[3:0];
    end

    // Stage 3: Process second half of stage 1 result
    stage2_enable2 <= stage1_enable;
    if (stage1_enable) begin
      stage2_result2 <= stage1_result[7:4] ^ stage1_result[3:0]; // Reusing same operation for demonstration
    end

    // Stage 4: Combine results from stage 2
    stage3_enable <= stage2_enable1 & stage2_enable2;
    if (stage3_enable) begin
      stage3_result <= stage2_result1[3:2] ^ stage2_result1[1:0] ^ stage2_result2[3:2] ^ stage2_result2[1:0];
    end

    // Stage 5: Final result
    stage4_enable <= stage3_enable;
    if (stage4_enable) begin
      parity_result <= stage3_result[1] ^ stage3_result[0];
    end
  end
endmodule