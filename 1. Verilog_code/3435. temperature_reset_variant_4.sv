//SystemVerilog
/////////////////////////////////////////////////////////////
// Module: temperature_reset
// Description: Temperature monitoring with enhanced pipelined architecture
// Standard: IEEE 1364-2005
/////////////////////////////////////////////////////////////
module temperature_reset #(
  parameter HOT_THRESHOLD = 8'hC0
) (
  input wire clk,
  input wire [7:0] temperature,
  input wire rst_n,
  input wire valid_in,         // Input data valid signal
  output wire ready_in,        // Ready to accept new input
  output reg temp_reset,
  output reg valid_out         // Output data valid signal
);

  // Split temperature comparison into multiple stages
  // Stage 0: Initial comparison (purely combinational)
  wire [7:0] temperature_diff = temperature - HOT_THRESHOLD;
  wire comparison_sign = temperature_diff[7];
  
  // Pipeline stage 1 registers - register input data and intermediate results
  reg [7:0] temperature_stage1;
  reg [7:0] temperature_diff_stage1;
  reg comparison_sign_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 registers - further processing
  reg comparison_sign_stage2;
  reg comparison_result_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers - additional processing
  reg comparison_result_stage3;
  reg valid_stage3;
  
  // Pipeline stage 4 registers - final processing
  reg comparison_result_stage4;
  reg valid_stage4;
  
  // Flow control - always ready to accept new data in this implementation
  assign ready_in = 1'b1;
  
  // Pipeline stage 1: Register input data and intermediate results
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      temperature_stage1 <= 8'h0;
      temperature_diff_stage1 <= 8'h0;
      comparison_sign_stage1 <= 1'b0;
      valid_stage1 <= 1'b0;
    end else begin
      temperature_stage1 <= temperature;
      temperature_diff_stage1 <= temperature_diff;
      comparison_sign_stage1 <= comparison_sign;
      valid_stage1 <= valid_in;
    end
  end
  
  // Pipeline stage 2: Process the comparison
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      comparison_sign_stage2 <= 1'b0;
      comparison_result_stage2 <= 1'b0;
      valid_stage2 <= 1'b0;
    end else begin
      comparison_sign_stage2 <= comparison_sign_stage1;
      // When comparison_sign is 0, temperature is greater (unsigned comparison)
      comparison_result_stage2 <= ~comparison_sign_stage1;
      valid_stage2 <= valid_stage1;
    end
  end
  
  // Pipeline stage 3: Additional processing stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      comparison_result_stage3 <= 1'b0;
      valid_stage3 <= 1'b0;
    end else begin
      comparison_result_stage3 <= comparison_result_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Pipeline stage 4: Final processing stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      comparison_result_stage4 <= 1'b0;
      valid_stage4 <= 1'b0;
    end else begin
      comparison_result_stage4 <= comparison_result_stage3;
      valid_stage4 <= valid_stage3;
    end
  end
  
  // Output stage
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      temp_reset <= 1'b0;
      valid_out <= 1'b0;
    end else begin
      temp_reset <= comparison_result_stage4;
      valid_out <= valid_stage4;
    end
  end

endmodule