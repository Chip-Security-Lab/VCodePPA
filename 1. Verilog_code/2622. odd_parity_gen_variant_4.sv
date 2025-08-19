//SystemVerilog
module odd_parity_gen(
  input clk,
  input rst_n,
  input [7:0] data_input,
  output reg odd_parity
);

  // Stage 1: First level XOR pairs
  reg [3:0] xor_stage1;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      xor_stage1 <= 4'b0;
    end else begin
      xor_stage1[0] <= data_input[0] ^ data_input[1];
      xor_stage1[1] <= data_input[2] ^ data_input[3];
      xor_stage1[2] <= data_input[4] ^ data_input[5];
      xor_stage1[3] <= data_input[6] ^ data_input[7];
    end
  end

  // Stage 2: Second level XOR pairs
  reg [1:0] xor_stage2;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      xor_stage2 <= 2'b0;
    end else begin
      xor_stage2[0] <= xor_stage1[0] ^ xor_stage1[1];
      xor_stage2[1] <= xor_stage1[2] ^ xor_stage1[3];
    end
  end

  // Stage 3: Final XOR and parity generation
  reg xor_stage3;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      xor_stage3 <= 1'b0;
      odd_parity <= 1'b0;
    end else begin
      xor_stage3 <= xor_stage2[0] ^ xor_stage2[1];
      odd_parity <= ~xor_stage3;
    end
  end

endmodule