//SystemVerilog
module strobe_sync (
    input wire clk_a,
    input wire clk_b,
    input wire reset,
    input wire data_a,
    input wire strobe_a,
    output reg data_b,
    output reg strobe_b
);

    // ---------------- Source Domain Pipeline ----------------
    reg data_a_capture_stage1;
    reg data_a_capture_stage2;
    reg toggle_a_stage1;
    reg toggle_a_stage2;

    // Pipeline: Capture data and toggle in clk_a domain
    always @(posedge clk_a) begin
        if (reset) begin
            data_a_capture_stage1 <= 1'b0;
            data_a_capture_stage2 <= 1'b0;
            toggle_a_stage1 <= 1'b0;
            toggle_a_stage2 <= 1'b0;
        end else if (strobe_a) begin
            data_a_capture_stage1 <= data_a;
            data_a_capture_stage2 <= data_a_capture_stage1;
            toggle_a_stage1 <= ~toggle_a_stage1;
            toggle_a_stage2 <= toggle_a_stage1;
        end
    end

    // ---------------- Toggle Synchronization Pipeline ----------------
    reg toggle_sync_stage1;
    reg toggle_sync_stage2;
    reg toggle_sync_stage3;

    // Pipeline: Synchronize toggle from clk_a to clk_b domain
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_sync_stage1 <= 1'b0;
            toggle_sync_stage2 <= 1'b0;
            toggle_sync_stage3 <= 1'b0;
        end else begin
            toggle_sync_stage1 <= toggle_a_stage2;
            toggle_sync_stage2 <= toggle_sync_stage1;
            toggle_sync_stage3 <= toggle_sync_stage2;
        end
    end

    // ---------------- Data Transfer Pipeline ----------------
    reg data_b_pipeline;
    reg strobe_b_pipeline;

    // Pipeline: Latch data and strobe in clk_b domain
    always @(posedge clk_b) begin
        if (reset) begin
            data_b_pipeline <= 1'b0;
            strobe_b_pipeline <= 1'b0;
            data_b <= 1'b0;
            strobe_b <= 1'b0;
        end else begin
            // Detect toggle edge for strobe generation
            if ((toggle_sync_stage2 ^ toggle_sync_stage3) == 1'b1) begin
                strobe_b_pipeline <= 1'b1;
                data_b_pipeline <= data_a_capture_stage2;
            end else begin
                strobe_b_pipeline <= 1'b0;
            end

            // Output register stage for clean timing
            strobe_b <= strobe_b_pipeline;
            data_b <= data_b_pipeline;
        end
    end

endmodule