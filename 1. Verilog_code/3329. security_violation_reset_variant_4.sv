//SystemVerilog
module security_violation_reset(
  input  wire        clk,
  input  wire        rst_n,
  input  wire [3:0]  access_violations, // Memory protection violations
  input  wire [3:0]  crypto_alerts,     // Cryptographic check failures
  input  wire [3:0]  tamper_detections, // Physical tamper detections
  input  wire [3:0]  violation_mask,    // Enable specific violation types
  output reg         security_violation,
  output reg  [2:0]  violation_type,
  output reg         secure_reset
);

  // Stage 1: Masking violations
  reg [3:0] access_violations_masked_stage1;
  reg [3:0] crypto_alerts_masked_stage1;
  reg [3:0] tamper_detections_masked_stage1;

  // Stage 2: OR combinations
  reg [3:0] violations_combined_stage2;

  // Stage 3: Violation flags for priority encoder
  reg tamper_violation_flag_stage3;
  reg crypto_violation_flag_stage3;
  reg access_violation_flag_stage3;

  // Stage 4: Priority encoder outputs
  reg [2:0] violation_type_stage4;
  reg       security_violation_stage4;
  reg       secure_reset_stage4;

  // Stage 1: Register masking for all violation sources
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      access_violations_masked_stage1  <= 4'b0;
      crypto_alerts_masked_stage1      <= 4'b0;
      tamper_detections_masked_stage1  <= 4'b0;
    end else begin
      access_violations_masked_stage1  <= access_violations   & {4{violation_mask[0]}};
      crypto_alerts_masked_stage1      <= crypto_alerts       & {4{violation_mask[1]}};
      tamper_detections_masked_stage1  <= tamper_detections   & {4{violation_mask[2]}};
    end
  end

  // Stage 2: Combine all violation sources
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      violations_combined_stage2 <= 4'b0;
    end else begin
      violations_combined_stage2 <= access_violations_masked_stage1 |
                                   crypto_alerts_masked_stage1     |
                                   tamper_detections_masked_stage1;
    end
  end

  // Stage 3: Generate flags for each violation type
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tamper_violation_flag_stage3   <= 1'b0;
      crypto_violation_flag_stage3   <= 1'b0;
      access_violation_flag_stage3   <= 1'b0;
    end else begin
      tamper_violation_flag_stage3   <= |tamper_detections_masked_stage1;
      crypto_violation_flag_stage3   <= |crypto_alerts_masked_stage1;
      access_violation_flag_stage3   <= |access_violations_masked_stage1;
    end
  end

  // Stage 4: Priority encoder and output assignment
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      violation_type_stage4       <= 3'b000;
      security_violation_stage4   <= 1'b0;
      secure_reset_stage4         <= 1'b0;
    end else begin
      security_violation_stage4   <= |violations_combined_stage2;
      secure_reset_stage4         <= |violations_combined_stage2;
      // Priority: tamper > crypto > access
      if (tamper_violation_flag_stage3)
        violation_type_stage4     <= 3'b001;
      else if (crypto_violation_flag_stage3)
        violation_type_stage4     <= 3'b010;
      else if (access_violation_flag_stage3)
        violation_type_stage4     <= 3'b011;
      else
        violation_type_stage4     <= 3'b000;
    end
  end

  // Stage 5: Final output register stage for timing closure
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      security_violation <= 1'b0;
      violation_type     <= 3'b000;
      secure_reset       <= 1'b0;
    end else begin
      security_violation <= security_violation_stage4;
      violation_type     <= violation_type_stage4;
      secure_reset       <= secure_reset_stage4;
    end
  end

endmodule