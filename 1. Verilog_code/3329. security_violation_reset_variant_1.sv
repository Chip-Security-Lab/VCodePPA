//SystemVerilog
module security_violation_reset(
  input clk, rst_n,
  input [3:0] access_violations, // Memory protection violations
  input [3:0] crypto_alerts,     // Cryptographic check failures
  input [3:0] tamper_detections, // Physical tamper detections
  input [3:0] violation_mask,    // Enable specific violation types
  output reg security_violation,
  output reg [2:0] violation_type,
  output reg secure_reset
);

  wire [3:0] masked_access_violations;
  wire [3:0] masked_crypto_alerts;
  wire [3:0] masked_tamper_detections;
  wire [3:0] masked_violations;

  assign masked_access_violations = violation_mask[0] ? access_violations : 4'b0000;
  assign masked_crypto_alerts     = violation_mask[1] ? crypto_alerts     : 4'b0000;
  assign masked_tamper_detections = violation_mask[2] ? tamper_detections : 4'b0000;

  assign masked_violations = masked_access_violations | masked_crypto_alerts | masked_tamper_detections;

  wire tamper_violation_active = |masked_tamper_detections;
  wire crypto_violation_active = |masked_crypto_alerts;
  wire access_violation_active = |masked_access_violations;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      security_violation <= 1'b0;
      violation_type <= 3'b000;
      secure_reset <= 1'b0;
    end else begin
      security_violation <= |masked_violations;

      // Priority encoder for violation type
      if (tamper_violation_active)
        violation_type <= 3'b001;
      else if (crypto_violation_active)
        violation_type <= 3'b010;
      else if (access_violation_active)
        violation_type <= 3'b011;
      else
        violation_type <= 3'b000;

      secure_reset <= security_violation;
    end
  end

endmodule