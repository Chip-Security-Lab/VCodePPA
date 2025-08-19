//SystemVerilog
module reset_sync_mem_wr (
  input  wire clk,      // Clock input
  input  wire rst_n,    // Active-low asynchronous reset
  input  wire wr_data,  // Write data input
  output reg  mem_out   // Memory output
);

  // Intermediate registers for multi-stage synchronization pipeline
  reg stage1_reg;
  reg stage2_reg;
  reg stage3_reg;
  reg stage4_reg;

  // Reset and data transfer logic with deeper pipeline structure
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Parallel reset of all pipeline registers
      {stage1_reg, stage2_reg, stage3_reg, stage4_reg, mem_out} <= 5'b00000;
    end else begin
      // Enhanced pipeline with more stages for better timing margin
      stage1_reg <= wr_data;     // First pipeline stage
      stage2_reg <= stage1_reg;  // Second pipeline stage
      stage3_reg <= stage2_reg;  // Third pipeline stage
      stage4_reg <= stage3_reg;  // Fourth pipeline stage
      mem_out    <= stage4_reg;  // Output stage
    end
  end

endmodule