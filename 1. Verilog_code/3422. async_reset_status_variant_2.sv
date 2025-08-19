//SystemVerilog
module async_reset_status (
  input wire clk,
  input wire reset,
  // Valid-Ready interface signals
  input wire ready,
  output wire valid,
  output wire reset_active,
  output reg [3:0] reset_count
);

  // Pipeline registers
  reg reset_stage1, reset_stage2;
  reg [3:0] reset_count_stage1;
  reg valid_stage1, valid_stage2;
  reg ready_stage1, ready_stage2;
  reg increment_stage1, increment_stage2, increment_stage3;
  
  // Reset activity signal - pipelined through multiple stages
  assign reset_active = reset;
  
  // Valid signal assertion - moved to pipeline stages
  assign valid = valid_stage2;
  
  // First pipeline stage - capture inputs and calculate initial conditions
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_stage1 <= 1'b1;
      reset_count_stage1 <= 4'd0;
      valid_stage1 <= 1'b1;  // Valid during reset
      ready_stage1 <= 1'b0;
      increment_stage1 <= 1'b0;
    end
    else begin
      reset_stage1 <= 1'b0;
      reset_count_stage1 <= reset_count;
      valid_stage1 <= (reset_count < 4'hF) || reset;
      ready_stage1 <= ready;
      increment_stage1 <= valid && ready && (reset_count < 4'hF);
    end
  end
  
  // Second pipeline stage - propagate signals and prepare for final calculation
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_stage2 <= 1'b1;
      valid_stage2 <= 1'b1;  // Valid during reset
      ready_stage2 <= 1'b0;
      increment_stage2 <= 1'b0;
      increment_stage3 <= 1'b0;
    end
    else begin
      reset_stage2 <= reset_stage1;
      valid_stage2 <= valid_stage1;
      ready_stage2 <= ready_stage1;
      increment_stage2 <= increment_stage1;
      increment_stage3 <= increment_stage2;
    end
  end
  
  // Final stage - update reset counter based on pipelined control signals
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      reset_count <= 4'd0;
    end
    else if (increment_stage3) begin
      // Only increment when handshake is complete and counter below max
      reset_count <= reset_count + 4'd1;
    end
  end
  
endmodule