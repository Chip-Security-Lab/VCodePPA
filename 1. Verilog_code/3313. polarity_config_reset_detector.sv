module polarity_config_reset_detector(
  input clk, rst_n,
  input [3:0] reset_inputs,
  input [3:0] polarity_config, // 0=active-low, 1=active-high
  output reg [3:0] detected_resets
);
  wire [3:0] normalized_inputs;
  assign normalized_inputs[0] = polarity_config[0] ? reset_inputs[0] : ~reset_inputs[0];
  assign normalized_inputs[1] = polarity_config[1] ? reset_inputs[1] : ~reset_inputs[1];
  assign normalized_inputs[2] = polarity_config[2] ? reset_inputs[2] : ~reset_inputs[2];
  assign normalized_inputs[3] = polarity_config[3] ? reset_inputs[3] : ~reset_inputs[3];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      detected_resets <= 4'b0000;
    else
      detected_resets <= normalized_inputs;
  end
endmodule