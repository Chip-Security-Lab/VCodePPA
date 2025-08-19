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
  wire [3:0] masked_violations = (
    (access_violations & {4{violation_mask[0]}}) |
    (crypto_alerts & {4{violation_mask[1]}}) |
    (tamper_detections & {4{violation_mask[2]}})
  );
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      security_violation <= 1'b0;
      violation_type <= 3'b000;
      secure_reset <= 1'b0;
    end else begin
      security_violation <= |masked_violations;
      
      // Determine violation type (priority encoded)
      if (|tamper_detections)
        violation_type <= 3'b001;
      else if (|crypto_alerts)
        violation_type <= 3'b010;
      else if (|access_violations)
        violation_type <= 3'b011;
      else
        violation_type <= 3'b000;
        
      secure_reset <= security_violation;
    end
  end
endmodule