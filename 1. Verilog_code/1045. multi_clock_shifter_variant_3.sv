//SystemVerilog
module multi_clock_shifter (
  input            clk_a,
  input            clk_b,
  input      [7:0] data_in,
  input      [2:0] shift_a,
  input      [2:0] shift_b,
  output reg [7:0] data_out
);

  // Stage 1: Shift in clk_a domain, registered output
  reg  [7:0] shifted_a_stage1;
  always @(posedge clk_a) begin
    shifted_a_stage1 <= data_in << shift_a;
  end

  // Stage 2: Register shift result in clk_a domain for CDC synchronization
  reg [7:0] shifted_a_stage2;
  always @(posedge clk_a) begin
    shifted_a_stage2 <= shifted_a_stage1;
  end

  // Stage 3: Cross domain register (clk_a to clk_b) - CDC
  reg [7:0] cdc_reg_stage1;
  reg [7:0] cdc_reg_stage2;
  always @(posedge clk_b) begin
    cdc_reg_stage1 <= shifted_a_stage2;
    cdc_reg_stage2 <= cdc_reg_stage1;
  end

  // Stage 4: Right shift LSBs in clk_b domain, registered
  reg [7:0] shifted_b_stage1;
  always @(posedge clk_b) begin
    shifted_b_stage1 <= cdc_reg_stage2 >> (shift_b[1:0]); // split shift into two stages
  end

  // Stage 5: Final right shift in clk_b domain, registered output
  reg [7:0] shifted_b_stage2;
  always @(posedge clk_b) begin
    shifted_b_stage2 <= shifted_b_stage1 >> {1'b0, shift_b[2]}; // remaining bit
    data_out <= shifted_b_stage2;
  end

endmodule