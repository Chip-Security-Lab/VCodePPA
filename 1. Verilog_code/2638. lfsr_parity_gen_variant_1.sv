//SystemVerilog
module lfsr_parity_gen_pipeline(
  input clk, rst,
  input [7:0] data_in,
  output reg parity
);
  reg [3:0] lfsr_stage1, lfsr_stage2;
  reg parity_stage1, parity_stage2;
  reg valid_stage1, valid_stage2;

  // Stage 1: LFSR calculation
  always @(posedge clk) begin
    if (rst) begin
      lfsr_stage1 <= 4'b1111;
      valid_stage1 <= 1'b0;
    end else begin
      lfsr_stage1 <= {lfsr_stage1[2:0], lfsr_stage1[3] ^ lfsr_stage1[2]};
      valid_stage1 <= 1'b1;
    end
  end

  // Stage 2: Parity calculation
  always @(posedge clk) begin
    if (rst) begin
      lfsr_stage2 <= 4'b1111;
      parity_stage1 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else if (valid_stage1) begin
      lfsr_stage2 <= lfsr_stage1;
      parity_stage1 <= (^data_in) ^ lfsr_stage1[0];
      valid_stage2 <= 1'b1;
    end else begin
      valid_stage2 <= 1'b0;
    end
  end

  // Output stage
  always @(posedge clk) begin
    if (rst) begin
      parity <= 1'b0;
    end else if (valid_stage2) begin
      parity <= parity_stage1;
    end
  end
endmodule