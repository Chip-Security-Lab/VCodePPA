//SystemVerilog
module pipelined_parity_gen(
  input clk, rst_n,
  input [31:0] data_in,
  input data_valid,
  output reg parity_out,
  output reg data_valid_out
);

  // Stage 1 registers - split data processing
  reg [7:0] stage1_data1, stage1_data2, stage1_data3, stage1_data4;
  reg stage1_valid;
  
  // Stage 2 registers - intermediate parity calculations
  reg stage2_parity1, stage2_parity2, stage2_parity3, stage2_parity4;
  reg stage2_valid;
  
  // Stage 3 registers - combined parity calculations
  reg stage3_parity_lo, stage3_parity_hi;
  reg stage3_valid;

  // Stage 1: Split data and calculate initial parity
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {stage1_data1, stage1_data2, stage1_data3, stage1_data4} <= 32'h0;
      stage1_valid <= 1'b0;
    end else begin
      {stage1_data1, stage1_data2, stage1_data3, stage1_data4} <= data_in;
      stage1_valid <= data_valid;
    end
  end
  
  // Stage 2: Calculate parity for each byte using parallel XOR trees
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {stage2_parity1, stage2_parity2, stage2_parity3, stage2_parity4} <= 4'h0;
      stage2_valid <= 1'b0;
    end else begin
      stage2_parity1 <= ^stage1_data1;
      stage2_parity2 <= ^stage1_data2;
      stage2_parity3 <= ^stage1_data3;
      stage2_parity4 <= ^stage1_data4;
      stage2_valid <= stage1_valid;
    end
  end
  
  // Stage 3: Combine parity of low and high halves using parallel XOR
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {stage3_parity_lo, stage3_parity_hi} <= 2'h0;
      stage3_valid <= 1'b0;
    end else begin
      stage3_parity_lo <= stage2_parity1 ^ stage2_parity2;
      stage3_parity_hi <= stage2_parity3 ^ stage2_parity4;
      stage3_valid <= stage2_valid;
    end
  end
  
  // Final stage: Combine lo and hi parity bits
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      {parity_out, data_valid_out} <= 2'h0;
    end else begin
      parity_out <= stage3_parity_lo ^ stage3_parity_hi;
      data_valid_out <= stage3_valid;
    end
  end
endmodule