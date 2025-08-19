//SystemVerilog
module dual_reset_sync_pipeline (
    input  wire clock,
    input  wire reset_a_n,
    input  wire reset_b_n,
    output wire synchronized_reset_n
);
    // Optimized synchronous reset synchronizer pipeline

    wire combined_reset_n;
    assign combined_reset_n = reset_a_n & reset_b_n;

    reg stage1_ff;
    reg stage2_ff;
    reg stage3_ff;

    // Stage 1: Synchronize combined reset
    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n)
            stage1_ff <= 1'b0;
        else
            stage1_ff <= 1'b1;
    end

    // Stage 2: Synchronize output of stage 1
    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n)
            stage2_ff <= 1'b0;
        else
            stage2_ff <= stage1_ff;
    end

    // Stage 3: Synchronize output of stage 2
    always @(posedge clock or negedge combined_reset_n) begin
        if (!combined_reset_n)
            stage3_ff <= 1'b0;
        else
            stage3_ff <= stage2_ff;
    end

    assign synchronized_reset_n = stage3_ff;

endmodule