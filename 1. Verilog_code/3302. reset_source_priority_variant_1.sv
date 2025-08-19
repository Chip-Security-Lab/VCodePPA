//SystemVerilog
module reset_source_priority(
  input  pwr_fail,
  input  watchdog_timeout,
  input  manual_btn,
  input  brownout,
  output reg [1:0] reset_cause,
  output wire system_reset
);

// ========================
// Stage 1: Input Pipeline
// ========================
reg pwr_fail_stage1, watchdog_timeout_stage1, manual_btn_stage1, brownout_stage1;

always @(*) begin
    pwr_fail_stage1         = pwr_fail;
    watchdog_timeout_stage1 = watchdog_timeout;
    manual_btn_stage1       = manual_btn;
    brownout_stage1         = brownout;
end

// ========================
// Stage 2: Condition Decoding
// ========================
// Invert and prepare signals for logic clarity
reg pwr_fail_n_stage2, watchdog_timeout_n_stage2, brownout_n_stage2;

always @(*) begin
    pwr_fail_n_stage2         = ~pwr_fail_stage1;
    watchdog_timeout_n_stage2 = ~watchdog_timeout_stage1;
    brownout_n_stage2         = ~brownout_stage1;
end

// ========================
// Stage 3: Cause Term Generation
// ========================
// Pipeline the main cause terms for reset_cause calculation

reg cause1_term1_stage3, cause1_term2_stage3;
reg cause0_term1_stage3, cause0_term2_stage3;

always @(*) begin
    // reset_cause[1] terms
    cause1_term1_stage3 = watchdog_timeout_stage1 & pwr_fail_n_stage2 & brownout_n_stage2;
    cause1_term2_stage3 = manual_btn_stage1 & pwr_fail_n_stage2 & brownout_n_stage2 & watchdog_timeout_n_stage2;

    // reset_cause[0] terms
    cause0_term1_stage3 = brownout_stage1 & pwr_fail_n_stage2;
    cause0_term2_stage3 = manual_btn_stage1 & pwr_fail_n_stage2 & brownout_n_stage2 & watchdog_timeout_n_stage2;
end

// ========================
// Stage 4: Final Output Registering
// ========================
// Pipeline the cause vector for clarity and timing
reg [1:0] reset_cause_stage4;

always @(*) begin
    reset_cause_stage4[1] = cause1_term1_stage3 | cause1_term2_stage3;
    reset_cause_stage4[0] = cause0_term1_stage3 | cause0_term2_stage3;
end

// Output assignment
always @(*) begin
    reset_cause = reset_cause_stage4;
end

// ========================
// System Reset Output
// ========================
assign system_reset = pwr_fail_stage1 | watchdog_timeout_stage1 | manual_btn_stage1 | brownout_stage1;

endmodule