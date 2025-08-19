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

  // Buffer stage 1 for violation_mask
  reg [3:0] violation_mask_buf1;
  // Buffer stage 2 for violation_mask (for fanout splitting)
  reg [3:0] violation_mask_buf2;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      violation_mask_buf1 <= 4'b0;
      violation_mask_buf2 <= 4'b0;
    end else begin
      violation_mask_buf1 <= violation_mask;
      violation_mask_buf2 <= violation_mask_buf1;
    end
  end

  // Use buffered violation_mask signals to split fanout load
  wire [3:0] masked_access_violations  = access_violations  & {4{violation_mask_buf1[0]}};
  wire [3:0] masked_crypto_alerts      = crypto_alerts      & {4{violation_mask_buf2[1]}};
  wire [3:0] masked_tamper_detections  = tamper_detections  & {4{violation_mask_buf1[2]}};
  wire [3:0] masked_violations         = masked_access_violations | masked_crypto_alerts | masked_tamper_detections;

  // Priority encoding: tamper > crypto > access
  wire tamper_violation = |masked_tamper_detections;
  wire crypto_violation = |masked_crypto_alerts;
  wire access_violation = |masked_access_violations;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      security_violation <= 1'b0;
      violation_type <= 3'b000;
      secure_reset <= 1'b0;
    end else begin
      security_violation <= |masked_violations;

      // Optimized priority encoder using case statement
      casez ({tamper_violation, crypto_violation, access_violation})
        3'b1??: violation_type <= 3'b001; // Tamper detected (highest priority)
        3'b01?: violation_type <= 3'b010; // Crypto detected
        3'b001: violation_type <= 3'b011; // Access detected
        default: violation_type <= 3'b000; // No violation
      endcase

      secure_reset <= |masked_violations;
    end
  end

endmodule