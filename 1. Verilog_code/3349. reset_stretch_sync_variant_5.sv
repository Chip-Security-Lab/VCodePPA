//SystemVerilog
module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output reg  sync_rst_n
);

    // Stage 1: Async to meta-flop synchronizer (first stage)
    reg meta_stage1;
    reg meta_stage2;

    // Stage 2: Stretch logic pipeline registers
    reg [2:0] stretch_counter_stage1;
    reg [2:0] stretch_counter_stage2;
    reg reset_detected_stage1;
    reg reset_detected_stage2;

    // Stage 3: Output pipeline register
    reg sync_rst_n_stage1;

    // Merge all always blocks into a single always block, preserving logic order
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Stage 1 reset
            meta_stage1 <= 1'b0;
            meta_stage2 <= 1'b0;
            // Stage 2 reset
            stretch_counter_stage1 <= 3'b000;
            reset_detected_stage1 <= 1'b1;
            stretch_counter_stage2 <= 3'b000;
            reset_detected_stage2  <= 1'b1;
            // Stage 3 reset
            sync_rst_n_stage1 <= 1'b0;
            // Stage 4 reset
            sync_rst_n <= 1'b0;
        end else begin
            // Stage 1: Synchronize async_rst_n to clk domain (double-flop)
            meta_stage1 <= 1'b1;
            meta_stage2 <= meta_stage1;

            // Stage 2: Pipeline stretch counter and reset_detected
            if (reset_detected_stage1) begin
                if (stretch_counter_stage1 < STRETCH_COUNT - 1) begin
                    stretch_counter_stage1 <= stretch_counter_stage1 + 1'b1;
                end
            end
            if (stretch_counter_stage1 == STRETCH_COUNT - 1) begin
                reset_detected_stage1 <= 1'b0;
            end

            // Stage 2: Pipeline registers for next stage
            stretch_counter_stage2 <= stretch_counter_stage1;
            reset_detected_stage2  <= reset_detected_stage1;

            // Stage 3: Pipeline output logic
            if (reset_detected_stage2) begin
                if (stretch_counter_stage2 < STRETCH_COUNT - 1) begin
                    sync_rst_n_stage1 <= 1'b0;
                end else begin
                    sync_rst_n_stage1 <= 1'b1;
                end
            end else begin
                sync_rst_n_stage1 <= meta_stage2;
            end

            // Stage 4: Final output register
            sync_rst_n <= sync_rst_n_stage1;
        end
    end

endmodule