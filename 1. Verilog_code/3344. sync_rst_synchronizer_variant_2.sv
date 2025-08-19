//SystemVerilog
module sync_rst_synchronizer (
    input  wire clock,
    input  wire async_reset,
    input  wire sync_reset,
    output reg  reset_out
);

    // Stage 1: Capture async_reset, sync_reset
    reg meta_stage1;
    reg valid_stage1;
    reg async_reset_stage1;
    reg sync_reset_stage1;

    // Stage 2: Meta-flipflop
    reg meta_stage2;
    reg valid_stage2;
    reg sync_reset_stage2;

    // Stage 3: Output register
    reg reset_out_stage3;
    reg valid_stage3;

    // Stage 1: Register inputs
    always @(posedge clock) begin
        if (sync_reset) begin
            meta_stage1        <= 1'b1;
            async_reset_stage1 <= 1'b0;
            sync_reset_stage1  <= 1'b1;
            valid_stage1       <= 1'b1;
        end else begin
            meta_stage1        <= async_reset;
            async_reset_stage1 <= async_reset;
            sync_reset_stage1  <= sync_reset;
            valid_stage1       <= 1'b1;
        end
    end

    // Stage 2: Synchronizer meta flip-flop
    always @(posedge clock) begin
        if (sync_reset_stage1) begin
            meta_stage2     <= 1'b1;
            sync_reset_stage2 <= 1'b1;
            valid_stage2    <= valid_stage1;
        end else begin
            meta_stage2     <= meta_stage1;
            sync_reset_stage2 <= sync_reset_stage1;
            valid_stage2    <= valid_stage1;
        end
    end

    // Stage 3: Output register
    always @(posedge clock) begin
        if (sync_reset_stage2) begin
            reset_out_stage3 <= 1'b1;
            valid_stage3     <= valid_stage2;
        end else begin
            reset_out_stage3 <= meta_stage2;
            valid_stage3     <= valid_stage2;
        end
    end

    // Output assignment
    always @(posedge clock) begin
        if (sync_reset) begin
            reset_out <= 1'b1;
        end else if (valid_stage3) begin
            reset_out <= reset_out_stage3;
        end
    end

endmodule