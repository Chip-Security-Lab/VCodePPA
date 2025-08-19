//SystemVerilog
module sync_rst_synchronizer_pipeline (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    output reg  reset_out
);
    // Stage 1 registers
    reg meta_stage1;
    reg valid_stage1;
    reg async_reset_stage1;
    reg sync_reset_stage1;

    // Stage 2 registers
    reg meta_stage2;
    reg valid_stage2;
    reg sync_reset_stage2;

    // Stage 3 registers
    reg reset_out_stage3;
    reg valid_stage3;

    // Pipeline: Stage 1 - Input capture
    always @(posedge clock) begin
        async_reset_stage1 <= async_reset;
        sync_reset_stage1  <= sync_reset;
        valid_stage1       <= 1'b1;
    end

    // Pipeline: Stage 2 - Synchronization logic
    always @(posedge clock) begin
        sync_reset_stage2 <= sync_reset_stage1;
        valid_stage2      <= valid_stage1;

        if (sync_reset_stage1) begin
            meta_stage2 <= 1'b1;
        end else begin
            meta_stage2 <= async_reset_stage1;
        end
    end

    // Pipeline: Stage 3 - Output logic
    always @(posedge clock) begin
        valid_stage3 <= valid_stage2;

        if (sync_reset_stage2) begin
            reset_out_stage3 <= 1'b1;
        end else begin
            reset_out_stage3 <= meta_stage2;
        end
    end

    // Output assignment
    always @(posedge clock) begin
        if (valid_stage3) begin
            reset_out <= reset_out_stage3;
        end else begin
            reset_out <= 1'b0;
        end
    end

endmodule