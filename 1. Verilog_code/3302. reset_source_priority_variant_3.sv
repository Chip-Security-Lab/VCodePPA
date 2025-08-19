//SystemVerilog
module reset_source_priority(
    input  wire clk,
    input  wire rst_n,
    input  wire pwr_fail,
    input  wire watchdog_timeout,
    input  wire manual_btn,
    input  wire brownout,
    output reg  [1:0] reset_cause,
    output wire system_reset
);

    // Pipeline Stage 1: Input Synchronization
    reg pwr_fail_stage1, watchdog_timeout_stage1, manual_btn_stage1, brownout_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwr_fail_stage1        <= 1'b0;
            watchdog_timeout_stage1<= 1'b0;
            manual_btn_stage1      <= 1'b0;
            brownout_stage1        <= 1'b0;
        end else begin
            pwr_fail_stage1        <= pwr_fail;
            watchdog_timeout_stage1<= watchdog_timeout;
            manual_btn_stage1      <= manual_btn;
            brownout_stage1        <= brownout;
        end
    end

    // Pipeline Stage 2: Negate Power Fail and Brownout (Split from original stage 2)
    reg no_pwr_fail_stage2, no_brownout_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            no_pwr_fail_stage2   <= 1'b1;
            no_brownout_stage2   <= 1'b1;
        end else begin
            no_pwr_fail_stage2   <= ~pwr_fail_stage1;
            no_brownout_stage2   <= ~brownout_stage1;
        end
    end

    // Pipeline Stage 3: Prepare Gating for Watchdog, Manual, and Brownout (Further split)
    reg stage3_watchdog_gated, stage3_manual_gated, stage3_brownout_gated;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_watchdog_gated <= 1'b0;
            stage3_manual_gated   <= 1'b0;
            stage3_brownout_gated <= 1'b0;
        end else begin
            stage3_watchdog_gated <= no_pwr_fail_stage2 & no_brownout_stage2;
            stage3_manual_gated   <= no_pwr_fail_stage2 & no_brownout_stage2;
            stage3_brownout_gated <= no_pwr_fail_stage2 & brownout_stage1;
        end
    end

    // Pipeline Stage 4: Final Active Calculation for Each Reset Source (Further split)
    reg stage4_watchdog_active, stage4_manual_active, stage4_brownout_active;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage4_watchdog_active <= 1'b0;
            stage4_manual_active   <= 1'b0;
            stage4_brownout_active <= 1'b0;
        end else begin
            stage4_watchdog_active <= stage3_watchdog_gated & watchdog_timeout_stage1;
            stage4_manual_active   <= stage3_manual_gated & manual_btn_stage1;
            stage4_brownout_active <= stage3_brownout_gated;
        end
    end

    // Pipeline Stage 5: Register Results for Priority Logic
    reg stage5_watchdog_active, stage5_manual_active, stage5_brownout_active;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage5_watchdog_active <= 1'b0;
            stage5_manual_active   <= 1'b0;
            stage5_brownout_active <= 1'b0;
        end else begin
            stage5_watchdog_active <= stage4_watchdog_active;
            stage5_manual_active   <= stage4_manual_active;
            stage5_brownout_active <= stage4_brownout_active;
        end
    end

    // Pipeline Stage 6: Generate Reset Cause (Priority Logic)
    reg [1:0] reset_cause_stage6;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_cause_stage6 <= 2'b00;
        end else begin
            reset_cause_stage6[1] <= stage5_watchdog_active | stage5_manual_active;
            reset_cause_stage6[0] <= stage5_brownout_active | stage5_manual_active;
        end
    end

    // Output assign
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_cause <= 2'b00;
        end else begin
            reset_cause <= reset_cause_stage6;
        end
    end

    // System Reset Output (Registered for timing)
    reg system_reset_stage1, system_reset_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_reset_stage1 <= 1'b0;
            system_reset_stage2 <= 1'b0;
        end else begin
            system_reset_stage1 <= pwr_fail_stage1 | watchdog_timeout_stage1 | manual_btn_stage1 | brownout_stage1;
            system_reset_stage2 <= system_reset_stage1;
        end
    end

    assign system_reset = system_reset_stage2;

endmodule