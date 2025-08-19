//SystemVerilog
module polarity_config_reset_detector(
  input clk,
  input rst_n,
  input [3:0] reset_inputs,
  input [3:0] polarity_config, // 0=active-low, 1=active-high
  output reg [3:0] detected_resets
);

  reg [3:0] normalized_inputs_stage1;

  // Stage 1: Normalize each reset input according to its polarity configuration
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      normalized_inputs_stage1[0] <= 1'b0;
    end else begin
      normalized_inputs_stage1[0] <= polarity_config[0] ? reset_inputs[0] : ~reset_inputs[0];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      normalized_inputs_stage1[1] <= 1'b0;
    end else begin
      normalized_inputs_stage1[1] <= polarity_config[1] ? reset_inputs[1] : ~reset_inputs[1];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      normalized_inputs_stage1[2] <= 1'b0;
    end else begin
      normalized_inputs_stage1[2] <= polarity_config[2] ? reset_inputs[2] : ~reset_inputs[2];
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      normalized_inputs_stage1[3] <= 1'b0;
    end else begin
      normalized_inputs_stage1[3] <= polarity_config[3] ? reset_inputs[3] : ~reset_inputs[3];
    end
  end

  // Stage 2: Register the detected resets
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      detected_resets <= 4'b0000;
    end else begin
      detected_resets <= normalized_inputs_stage1;
    end
  end

endmodule