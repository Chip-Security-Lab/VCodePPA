//SystemVerilog
// Top-level module for even parity calculation with pipelined architecture
module top_even_parity #(
  parameter WIDTH = 16,
  parameter PIPELINE_STAGES = 2
)(
  input clk,
  input rst_n,
  input [WIDTH-1:0] data_bus,
  output reg parity_bit
);

  // Pipeline registers
  reg [WIDTH-1:0] data_stage1;
  reg [WIDTH/2-1:0] data_stage2;
  reg parity_stage1;
  
  // Stage 1: Data input and first level XOR
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage1 <= '0;
      parity_stage1 <= 1'b0;
    end else begin
      data_stage1 <= data_bus;
      parity_stage1 <= ^data_bus[WIDTH-1:WIDTH/2];
    end
  end

  // Stage 2: Second level XOR
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      data_stage2 <= '0;
    end else begin
      data_stage2 <= data_stage1[WIDTH/2-1:0];
    end
  end

  // Final stage: Combine results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      parity_bit <= 1'b0;
    end else begin
      parity_bit <= parity_stage1 ^ ^data_stage2;
    end
  end

endmodule