//SystemVerilog
//IEEE 1364-2005 Verilog
module reset_sync_mem_wr(
  input  wire clk,
  input  wire rst_n,
  input  wire wr_data,
  output reg  mem_out
);
  // Pipeline stage 1: Input data registration
  reg stage1_data_reg;
  
  // Pipeline stage 2: Output data registration
  reg stage2_data_reg;
  
  // Two-stage pipelined data path implementation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all pipeline registers
      stage1_data_reg <= 1'b0;
      stage2_data_reg <= 1'b0;
    end else begin
      // Normal pipeline operation
      stage1_data_reg <= wr_data;      // Stage 1: Register input data
      stage2_data_reg <= stage1_data_reg; // Stage 2: Transfer to output register
    end
  end
  
  // Assign pipeline output to module output
  always @(*) begin
    mem_out = stage2_data_reg;
  end
  
endmodule